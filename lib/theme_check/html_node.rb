# frozen_string_literal: true
require "forwardable"

module ThemeCheck
  class HtmlNode
    extend Forwardable
    include RegexHelpers
    attr_reader :template, :parent

    def initialize(value, template, placeholder_values = [], parent = nil)
      @value = value
      @template = template
      @placeholder_values = placeholder_values
      @parent = parent
    end

    def literal?
      @value.name == "text"
    end

    def element?
      @value.element?
    end

    def children
      @children ||= @value
        .children
        .map { |child| HtmlNode.new(child, template, @placeholder_values, self) }
    end

    def attributes
      @attributes ||= @value.attributes
        .map { |k, v| [replace_placeholders(k), replace_placeholders(v.value)] }
        .to_h
    end

    def content
      @content ||= replace_placeholders(@value.content)
    end

    # @value is not forwarded because we _need_ to replace the
    # placeholders for the HtmlNode to make sense.
    def value
      if literal?
        content
      else
        markup
      end
    end

    def name
      if @value.name == "#document-fragment"
        "document"
      else
        @value.name
      end
    end

    def markup
      @markup ||= replace_placeholders(@value.to_html)
    end

    def line_number
      @value.line
    end

    private

    def replace_placeholders(string)
      # Replace all ≬{i}####≬ with the actual content.
      string.gsub(HTML_LIQUID_PLACEHOLDER) do |match|
        key = /[0-9a-z]+/.match(match)[0]
        @placeholder_values[key.to_i(36)]
      end
    end
  end
end
