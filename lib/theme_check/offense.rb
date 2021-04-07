# frozen_string_literal: true
module ThemeCheck
  Position = Struct.new(:line, :column)

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

      @line_number = if line_number
        line_number
      elsif @node
        @node.line_number
      end

      @start_position = nil
      @end_position = nil
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

    def start_line
      start_position.line
    end

    def start_column
      start_position.column
    end

    def end_line
      end_position.line
    end

    def end_column
      end_position.column
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

    def to_s
      if template
        "#{message} at #{location}"
      else
        message
      end
    end

    private

    def full_line(line)
      # Liquid::Template is 1-indexed.
      template.full_line(line + 1)
    end

    def lines_of_content
      @lines ||= markup.lines.map { |x| x.sub(/\n$/, '') }
    end

    # 0-indexed, inclusive
    def start_position
      return @start_position if @start_position
      return @start_position = Position.new(0, 0) unless line_number && markup

      position = Position.new
      position.line = line_number - 1
      position.column = full_line(position.line).index(lines_of_content.first) || 0

      @start_position = position
    end

    # 0-indexed, exclusive. It's the line + col that are exclusive.
    # This is why it doesn't make sense to calculate them separately.
    def end_position
      return @end_position if @end_position
      return @end_position = Position.new(0, 0) unless line_number && markup

      position = Position.new
      position.line = start_line + lines_of_content.size - 1
      position.column = if start_line == position.line
        start_column + markup.size
      else
        lines_of_content.last.size
      end

      @end_position = position
    end
  end
end
