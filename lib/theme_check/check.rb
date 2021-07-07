# frozen_string_literal: true
require_relative "json_helpers"

module ThemeCheck
  class Check
    include JsonHelpers

    attr_accessor :theme
    attr_accessor :options, :ignored_patterns
    attr_writer :offenses

    # The order matters.
    SEVERITIES = [
      :error,
      :suggestion,
      :style,
    ]

    # [severity: sym] => number
    SEVERITY_VALUES = SEVERITIES
      .map
      .with_index { |sev, i| [sev, i] }
      .to_h

    CATEGORIES = [
      :liquid,
      :translation,
      :html,
      :json,
      :performance,
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

      def severity_value(severity)
        SEVERITY_VALUES[severity]
      end

      def categories(*categories)
        @categories ||= []
        if categories.any?
          unknown_categories = categories.select { |category| !CATEGORIES.include?(category) }
          if unknown_categories.any?
            raise ArgumentError,
              "unknown categories: #{unknown_categories.join(', ')}. Use: #{CATEGORIES.join(', ')}"
          end
          @categories = categories
        end
        @categories
      end
      alias_method :category, :categories

      def doc(doc = nil)
        @doc = doc if doc
        @doc if defined?(@doc)
      end

      def docs_url(path)
        "https://github.com/Shopify/theme-check/blob/main/docs/checks/#{File.basename(path, '.rb')}.md"
      end

      def can_disable(disableable = nil)
        unless disableable.nil?
          @can_disable = disableable
        end
        defined?(@can_disable) ? @can_disable : true
      end

      def single_file(single_file = nil)
        unless single_file.nil?
          @single_file = single_file
        end
        defined?(@single_file) ? @single_file : !method_defined?(:on_end)
      end
    end

    def offenses
      @offenses ||= []
    end

    def add_offense(message, node: nil, template: node&.template, markup: nil, line_number: nil, &block)
      offenses << Offense.new(check: self, message: message, template: template, node: node, markup: markup, line_number: line_number, correction: block)
    end

    def severity
      @severity ||= self.class.severity
    end

    def severity=(severity)
      unless SEVERITIES.include?(severity)
        raise ArgumentError, "unknown severity. Use: #{SEVERITIES.join(', ')}"
      end
      @severity = severity
    end

    def severity_value
      SEVERITY_VALUES[severity]
    end

    def categories
      self.class.categories
    end

    def doc
      self.class.doc
    end

    def code_name
      StringHelpers.demodulize(self.class.name)
    end

    def ignore!
      @ignored = true
    end

    def ignored?
      defined?(@ignored) && @ignored
    end

    def can_disable?
      self.class.can_disable
    end

    def single_file?
      self.class.single_file
    end

    def whole_theme?
      !single_file?
    end

    def ==(other)
      other.is_a?(Check) && code_name == other.code_name
    end
    alias_method :eql?, :==

    def to_s
      s = +"#{code_name}:\n"
      properties = {
        severity: severity,
        categories: categories,
        doc: doc,
        ignored_patterns: ignored_patterns,
      }.merge(options)
      properties.each_pair do |name, value|
        s << "  #{name}: #{value}\n" if value
      end
      s
    end
  end
end
