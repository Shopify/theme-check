# frozen_string_literal: true
require "forwardable"

module ThemeCheck
  class HtmlNode
    extend Forwardable
    attr_reader :template

    def_delegators :@value, :content, :attributes

    def initialize(value, template)
      @value = value
      @template = template
    end

    def literal?
      @value.name == "text"
    end

    def element?
      @value.element?
    end

    def children
      @value.children.map { |child| HtmlNode.new(child, template) }
    end

    def parent
      HtmlNode.new(@value.parent, template)
    end

    def name
      if @value.name == "#document-fragment"
        "document"
      else
        @value.name
      end
    end

    def value
      if literal?
        @value.content
      else
        @value
      end
    end

    def markup
      @value.to_html
    end

    def line_number
      @value.line
    end
  end
end
