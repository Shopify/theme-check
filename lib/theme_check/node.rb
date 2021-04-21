# frozen_string_literal: true

module ThemeCheck
  # A node from the Liquid AST, the result of parsing a template.
  class Node
    attr_reader :value, :parent, :template

    def initialize(value, parent, template)
      raise ArgumentError, "Expected a Liquid AST Node" if value.is_a?(Node)
      @value = value
      @parent = parent
      @template = template
    end

    # The original source code of the node. Doesn't contain wrapping braces.
    def markup
      if tag?
        @value.raw
      elsif @value.instance_variable_defined?(:@markup)
        @value.instance_variable_get(:@markup)
      end
    end

    def markup=(markup)
      if tag?
        @value.raw = markup
      elsif @value.instance_variable_defined?(:@markup)
        @value.instance_variable_set(:@markup, markup)
      end
    end

    # Array of children nodes.
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

    # Literals are hard-coded values in the template.
    def literal?
      @value.is_a?(String) || @value.is_a?(Integer)
    end

    # A {% tag %} node?
    def tag?
      @value.is_a?(Liquid::Tag)
    end

    # A {% comment %} block node?
    def comment?
      @value.is_a?(Liquid::Comment)
    end

    # Top level node of every template.
    def document?
      @value.is_a?(Liquid::Document)
    end
    alias_method :root?, :document?

    # A {% tag %}...{% endtag %} node?
    def block_tag?
      @value.is_a?(Liquid::Block)
    end

    # The body of blocks
    def block_body?
      @value.is_a?(Liquid::BlockBody)
    end

    # A block of type of node?
    def block?
      block_tag? || block_body? || document?
    end

    # Most nodes have a line number, but it's not guaranteed.
    def line_number
      @value.line_number if @value.respond_to?(:line_number)
    end

    # The `:under_score_name` of this type of node. Used to dispatch to the `on_<type_name>`
    # and `after_<type_name>` check methods.
    def type_name
      @type_name ||= StringHelpers.underscore(StringHelpers.demodulize(@value.class.name)).to_sym
    end

    # Is this node inside a `{% liquid ... %}` block?
    def inside_liquid_tag?
      if line_number
        template.excerpt(line_number).start_with?("{%")
      else
        false
      end
    end

    # Is this node inside a `{%- ... -%}`
    def whitespace_trimmed?
      if line_number
        template.excerpt(line_number).start_with?("{%-")
      else
        false
      end
    end

    def range
      start = template.full_line(line_number).index(markup)
      [start, start + markup.length - 1]
    end

    def position
      @position ||= Position.new(markup, template&.source, line_number)
    end

    def start_index
      position.start_index
    end

    def end_index
      position.end_index
    end
  end
end
