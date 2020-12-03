# frozen_string_literal: true
module ThemeCheck
  class Offense
    MAX_SOURCE_EXCERPT_SIZE = 120

    attr_reader :check, :message, :template, :node, :markup, :line_number

    def initialize(check:, message: nil, template: nil, node: nil, markup: nil, line_number: nil)
      @check = check

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
        excerpt = template.excerpt(line_number)
        if excerpt.size > MAX_SOURCE_EXCERPT_SIZE
          excerpt[0, MAX_SOURCE_EXCERPT_SIZE - 3] + '...'
        else
          excerpt
        end
      end
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
      [template&.relative_path, line_number].compact.join(":")
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
