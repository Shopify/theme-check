# frozen_string_literal: true
require 'active_support/core_ext/string/inflections'

module ThemeCheck
  class Node
    attr_reader :value, :parent, :template

    def initialize(value, parent, template)
      raise ArgumentError, "Expected a Liquid AST Node" if value.is_a?(Node)
      @value = value
      @parent = parent
      @template = template
    end

    def children
      @children ||= begin
        nodes =
          if comment?
            []
          elsif defined?(@value.class::ParseTreeVisitor)
            @value.class::ParseTreeVisitor.new(@value, {}).children
          elsif @value.respond_to?(:nodelist)
            Array(@value.nodelist)
          else
            []
          end
        # Work around a bug in Liquid::Variable::ParseTreeVisitor that doesn't return
        # the args in a hash as children nodes.
        nodes = nodes.flat_map do |node|
          case node
          when Hash
            node.values
          else
            node
          end
        end
        nodes.map { |node| Node.new(node, self, @template) }
      end
    end

    def literal?
      @value.is_a?(String) || @value.is_a?(Integer)
    end

    def tag?
      @value.is_a?(Liquid::Tag)
    end

    def comment?
      @value.is_a?(Liquid::Comment)
    end

    def document?
      @value.is_a?(Liquid::Document)
    end
    alias_method :root?, :document?

    def block_tag?
      @value.is_a?(Liquid::Block)
    end

    def block?
      block_tag? || block_body? || document?
    end

    def block_body?
      @value.is_a?(Liquid::BlockBody)
    end

    def line_number
      @value.line_number if @value.respond_to?(:line_number)
    end

    def type_name
      @type_name ||= @value.class.name.demodulize.underscore.to_sym
    end
  end
end
