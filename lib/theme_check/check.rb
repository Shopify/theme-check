# frozen_string_literal: true
require_relative "json_helpers"

module ThemeCheck
  class Check
    include JsonHelpers

    attr_accessor :theme
    attr_accessor :offenses
    attr_accessor :options

    SEVERITIES = [
      :error,
      :suggestion,
      :style,
    ]

    CATEGORIES = [
      :liquid,
      :translation,
      :performance,
      :json,
    ]

    class << self
      def all
        @all ||= []
      end

      def severity(severity = nil)
        if severity
          unless SEVERITIES.include?(severity)
            raise ArgumentError, "unknown severity. Use: #{SEVERITIES.join(', ')}"
          end
          @severity = severity
        end
        @severity if defined?(@severity)
      end

      def category(category = nil)
        if category
          unless CATEGORIES.include?(category)
            raise ArgumentError, "unknown category. Use: #{CATEGORIES.join(', ')}"
          end
          @category = category
        end
        @category if defined?(@category)
      end

      def doc(doc = nil)
        @doc = doc if doc
        @doc if defined?(@doc)
      end

      def can_disable(disableable = nil)
        unless disableable.nil?
          @can_disable = disableable
        end
        defined?(@can_disable) ? @can_disable : true
      end
    end

    def severity
      self.class.severity
    end

    def category
      self.class.category
    end

    def doc
      self.class.doc
    end

    def code_name
      self.class.name.demodulize
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

    def can_disable?
      self.class.can_disable
    end

    def to_s
      s = +"#{code_name}:\n"
      properties = { severity: severity, category: category, doc: doc }.merge(options)
      properties.each_pair do |name, value|
        s << "  #{name}: #{value}\n" if value
      end
      s
    end
  end
end
