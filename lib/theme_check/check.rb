# frozen_string_literal: true
require_relative "parsing_helpers"

module ThemeCheck
  class Check
    include ParsingHelpers

    attr_accessor :theme
    attr_accessor :offenses

    SEVERITIES = [
      :error,
      :suggestion,
      :style,
    ]

    class << self
      def all
        @all ||= []
      end

      def inherited(klass)
        all << klass
      end

      def severity(severity = nil)
        if severity
          unless SEVERITIES.include?(severity)
            raise ArgumentError, "unknown severity. Use: #{SEVERITIES.join(', ')}"
          end
          @severity = severity
        end
        @severity
      end

      def doc(doc = nil)
        @doc = doc if doc
        @doc
      end
    end

    def severity
      self.class.severity
    end

    def doc
      self.class.doc
    end

    def ignore!
      @ignored = true
    end

    def unignore!
      @ignored = false
    end

    def ignored?
      defined?(@ignored) && @ignored
    end

    def add_offense(message, node: nil, template: node&.template)
      offenses << Offense.new(self, template, node, message)
    end
  end
end
