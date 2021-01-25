# frozen_string_literal: true

module ThemeCheck
  class DisabledChecks
    DISABLE_START = 'theme-check-disable'
    DISABLE_END = 'theme-check-enable'

    DISABLE_PREFIX_PATTERN = /^#{DISABLE_START}|#{DISABLE_END}/

    def initialize
      @disabled = []
      @all_disabled = false
    end

    def update(node)
      text = comment_text(node)

      if start_disabling?(text)
        @disabled = checks_from_text(text)
        @all_disabled = @disabled.empty?
      elsif stop_disabling?(text)
        checks = checks_from_text(text)
        @disabled = checks.empty? ? [] : @disabled - checks

        @all_disabled = false
      end
    end

    # Whether any checks are currently disabled
    def any?
      !@disabled.empty? || @all_disabled
    end

    # Whether all checks should be disabled
    def all_disabled?
      @all_disabled
    end

    # Get a list of all the individual disabled checks
    def all
      @disabled
    end

    private

    def comment_text(node)
      node.value.nodelist.join
    end

    def start_disabling?(text)
      text.starts_with?(DISABLE_START)
    end

    def stop_disabling?(text)
      text.starts_with?(DISABLE_END)
    end

    # Return a list of checks from a theme-check-disable comment
    # Returns [] if all checks are meant to be disabled
    def checks_from_text(text)
      text.gsub(DISABLE_PREFIX_PATTERN, '').strip.split(',').map(&:strip)
    end
  end
end
