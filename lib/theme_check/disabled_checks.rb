# frozen_string_literal: true

module ThemeCheck
  class DisabledChecks
    DISABLE_START = 'theme-check-disable'
    DISABLE_END = 'theme-check-enable'
    DISABLE_PREFIX_PATTERN = /#{DISABLE_START}|#{DISABLE_END}/

    ACTION_DISABLE_CHECKS = :disable
    ACTION_ENABLE_CHECKS = :enable

    def initialize
      @disabled_checks = Hash.new do |hash, key|
        theme_file, check_name = key
        hash[key] = DisabledCheck.new(theme_file, check_name)
      end
    end

    def update(node)
      text = comment_text(node)
      if start_disabling?(text)
        checks_from_text(text).each do |check_name|
          disabled = @disabled_checks[[node.theme_file, check_name]]
          disabled.start_index = node.start_index
          disabled.first_line = true if node.line_number == 1
        end
      elsif stop_disabling?(text)
        checks_from_text(text).each do |check_name|
          disabled = @disabled_checks[[node.theme_file, check_name]]
          next unless disabled
          disabled.end_index = node.end_index
        end
      else
        # We want to disable checks inside comments
        # (e.g. html checks inside {% comment %})
        disabled = @disabled_checks[[node.theme_file, :all]]
        unless disabled.first_line
          disabled.start_index = node.inner_markup_start_index
          disabled.end_index = node.inner_markup_end_index
        end
      end
    end

    def disabled?(check, theme_file, check_name, index)
      return true if check.ignored_patterns&.any? do |pattern|
        theme_file&.relative_path&.fnmatch?(pattern)
      end

      @disabled_checks[[theme_file, :all]]&.disabled?(index) ||
        @disabled_checks[[theme_file, check_name]]&.disabled?(index)
    end

    def checks_missing_end_index
      @disabled_checks.values
        .select(&:missing_end_index?)
        .map(&:name)
    end

    def remove_disabled_offenses(checks)
      checks.disableable.each do |check|
        check.offenses.reject! do |offense|
          disabled?(check, offense.theme_file, offense.code_name, offense.start_index)
        end
      end
    end

    private

    def comment_text(node)
      case node.type_name
      when :comment
        node.value.nodelist.join
      when :inline_comment
        node.markup.sub(/\s*#+\s*/, '')
      end
    end

    def start_disabling?(text)
      text.strip.start_with?(DISABLE_START)
    end

    def stop_disabling?(text)
      text.strip.start_with?(DISABLE_END)
    end

    # Return a list of checks from a theme-check-disable comment
    # Returns [:all] if all checks are meant to be disabled
    def checks_from_text(text)
      checks = text.gsub(DISABLE_PREFIX_PATTERN, '').strip.split(',').map(&:strip)
      return [:all] if checks.empty?
      checks
    end
  end
end
