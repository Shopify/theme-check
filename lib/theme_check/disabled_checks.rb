# frozen_string_literal: true

module ThemeCheck
  class DisabledChecks
    DISABLE_START = 'theme-check-disable'
    DISABLE_END = 'theme-check-enable'
    DISABLE_PREFIX_PATTERN = /#{DISABLE_START}|#{DISABLE_END}/

    ACTION_DISABLE_CHECKS = :disable
    ACTION_ENABLE_CHECKS = :enable

    def initialize
      @disabled_checks = {}
    end

    def update(node)
      text = comment_text(node)
      if start_disabling?(text)
        checks_from_text(text).each do |check_name|
          @disabled_checks[check_name] ||= DisabledCheck.new(check_name)
          @disabled_checks[check_name].start_index = node.start_index
          @disabled_checks[check_name].first_line = true if node.line_number == 1
        end
      elsif stop_disabling?(text)
        checks_from_text(text).each do |check_name|
          next unless @disabled_checks.key?(check_name)
          @disabled_checks[check_name].end_index = node.end_index
        end
      end
    end

    def disabled?(key, index)
      @disabled_checks[:all]&.disabled?(index) ||
        @disabled_checks[key]&.disabled?(index)
    end

    def checks_missing_end_index
      @disabled_checks.values
        .select(&:missing_end_index?)
        .map(&:name)
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
