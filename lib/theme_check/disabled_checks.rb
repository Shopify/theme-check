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
        template, check_name = key
        hash[key] = DisabledCheck.new(template, check_name)
      end
    end

    def update(node)
      text = comment_text(node)
      if start_disabling?(text)
        checks_from_text(text).each do |check_name|
          disabled = @disabled_checks[[node.template, check_name]]
          disabled.start_index = node.start_index
          disabled.first_line = true if node.line_number == 1
        end
      elsif stop_disabling?(text)
        checks_from_text(text).each do |check_name|
          disabled = @disabled_checks[[node.template, check_name]]
          next unless disabled
          disabled.end_index = node.end_index
        end
      end
    end

    def disabled?(check, template, check_name, index)
      return true if check.ignored_patterns&.any? do |pattern|
        template.relative_path.fnmatch?(pattern)
      end

      @disabled_checks[[template, :all]]&.disabled?(index) ||
        @disabled_checks[[template, check_name]]&.disabled?(index)
    end

    def checks_missing_end_index
      @disabled_checks.values
        .select(&:missing_end_index?)
        .map(&:name)
    end

    def remove_disabled_offenses(checks)
      checks.disableable.each do |check|
        check.offenses.reject! do |offense|
          disabled?(check, offense.template, offense.code_name, offense.start_index)
        end
      end
    end

    private

    def comment_text(node)
      node.value.nodelist.join
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
