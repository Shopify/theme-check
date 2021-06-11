# frozen_string_literal: true
module ThemeCheck
  class Offense
    MAX_SOURCE_EXCERPT_SIZE = 120

    attr_reader :check, :message, :template, :node, :markup, :line_number, :correction

    def initialize(check:, message: nil, template: nil, node: nil, markup: nil, line_number: nil, correction: nil)
      @check = check
      @correction = correction

      if message
        @message = message
      elsif defined?(check.class::MESSAGE)
        @message = check.class::MESSAGE
      else
        raise ArgumentError, "message required"
      end

      @node = node
      @template = nil
      if node
        @template = node.template
      elsif template
        @template = template
      end

      @markup = if markup
        markup
      else
        node&.markup
      end

      raise ArgumentError, "Offense markup cannot be an empty string" if @markup.is_a?(String) && @markup.empty?

      @line_number = if line_number
        line_number
      elsif @node
        @node.line_number
      end

      @position = Position.new(@markup, @template&.source, @line_number)
    end

    def source_excerpt
      return unless line_number
      @source_excerpt ||= begin
        excerpt = template.source_excerpt(line_number)
        if excerpt.size > MAX_SOURCE_EXCERPT_SIZE
          excerpt[0, MAX_SOURCE_EXCERPT_SIZE - 3] + '...'
        else
          excerpt
        end
      end
    end

    def start_index
      @position.start_index
    end

    def start_line
      @position.start_row
    end

    def start_column
      @position.start_column
    end

    def end_index
      @position.end_index
    end

    def end_line
      @position.end_row
    end

    def end_column
      @position.end_column
    end

    def code_name
      check.code_name
    end

    def markup_start_in_excerpt
      source_excerpt.index(markup) if markup
    end

    def severity
      check.severity
    end

    def check_name
      StringHelpers.demodulize(check.class.name)
    end

    def doc
      check.doc
    end

    def location
      tokens = [template&.relative_path, line_number].compact
      tokens.join(":") if tokens.any?
    end

    def correctable?
      line_number && correction
    end

    def correct
      if correctable?
        corrector = Corrector.new(template: template)
        correction.call(corrector)
      end
    end

    def whole_theme?
      check.whole_theme?
    end

    def single_file?
      check.single_file?
    end

    def ==(other)
      other.is_a?(Offense) &&
        code_name == other.code_name &&
        message == other.message &&
        location == other.location &&
        start_index == other.start_index &&
        end_index == other.end_index
    end
    alias_method :eql?, :==

    def to_s
      if template
        "#{message} at #{location}"
      else
        message
      end
    end
  end
end
