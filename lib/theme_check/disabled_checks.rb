# frozen_string_literal: true

module ThemeCheck
  class DisabledCheck
    Range = Struct.new(:begin, :end)

    attr_reader :name
    attr_accessor :currently_disabled

    def initialize(name)
      @name = name
      @ranges = []
      @currently_disabled = false
    end

    def begin=(index)
      return unless @ranges.empty? || !last.end.nil?
      @currently_disabled = true
      @ranges << Range.new(index, nil)
    end

    def end=(index)
      return if @ranges.empty? || !last.end.nil?
      @currently_disabled = false
      last.end = index
    end

    def last
      @ranges.last
    end
  end

  class DisabledChecks
    DISABLE_START = 'theme-check-disable'
    DISABLE_END = 'theme-check-enable'
    DISABLE_PREFIX_PATTERN = /#{DISABLE_START}|#{DISABLE_END}/

    ACTION_DISABLE_CHECKS = :disable
    ACTION_ENABLE_CHECKS = :enable
    ACTION_UNRELATED_COMMENT = :unrelated

    def initialize
      @disabled_checks = {}
      @all_disabled = false
      @full_document_disabled = false
    end

    def update(node)
      text = comment_text(node)

      if start_disabling?(text)
        checks = checks_from_text(text)
        @all_disabled = checks.empty?

        checks.each do |check_name|
          @disabled_checks[check_name] ||= DisabledCheck.new(check_name)
          @disabled_checks[check_name].begin = node.begin
        end

        if node&.line_number == 1
          @full_document_disabled = true
        end
      elsif stop_disabling?(text)
        checks = checks_from_text(text)

        checks.each do |check_name|
          next unless @disabled_checks.key?(check_name)
          @disabled_checks[check_name].end = node.end
        end

        @all_disabled = false
      end
    end

    # Whether any checks are currently disabled
    def any?
      !all.empty? || @all_disabled
    end

    # Whether all checks should be disabled
    def all_disabled?
      @all_disabled
    end

    # Get a list of all the individual disabled checks
    def all
      @disabled_checks.values.select(&:currently_disabled).map(&:name)
    end

    # If the first line of the document is a theme-check-disable comment
    def full_document_disabled?
      @full_document_disabled
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
    # Returns [] if all checks are meant to be disabled
    def checks_from_text(text)
      text.gsub(DISABLE_PREFIX_PATTERN, '').strip.split(',').map(&:strip)
    end
  end
end
