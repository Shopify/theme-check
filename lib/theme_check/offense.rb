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
      return 0 unless line_number
      line_number - 1
    end

    def end_line
      if markup&.ends_with?("\n")
        start_line + markup.count("\n") - 1
      elsif markup
        start_line + markup.count("\n")
      else
        start_line
      end
    end

    def start_column
      return 0 unless line_number && markup
      template.full_line(start_line + 1).index(markup.split("\n", 2).first)
    end

    def end_column
      return 0 unless line_number && markup
      markup_end = markup.split("\n").last
      template.full_line(end_line + 1).index(markup_end) + markup_end.size
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
      check.class.name.demodulize
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
  end
end
