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
      @tag_markup = nil
      @line_number_offset = 0
    end

    # The original source code of the node. Doesn't contain wrapping braces.
    def markup
      if tag?
        tag_markup
      elsif @value.instance_variable_defined?(:@markup)
        @value.instance_variable_get(:@markup)
      end
    end

    def markup=(markup)
      if @value.instance_variable_defined?(:@markup)
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

    def variable?
      @value.is_a?(Liquid::Variable)
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
      if tag? && @value.respond_to?(:line_number)
        markup # initialize the line_number_offset
        @value.line_number - @line_number_offset
      elsif @value.respond_to?(:line_number)
        @value.line_number
      end
    end

    # The `:under_score_name` of this type of node. Used to dispatch to the `on_<type_name>`
    # and `after_<type_name>` check methods.
    def type_name
      @type_name ||= StringHelpers.underscore(StringHelpers.demodulize(@value.class.name)).to_sym
    end

    def source
      template&.source
    end

    WHITESPACE = /\s/

    # Is this node inside a `{% liquid ... %}` block?
    def inside_liquid_tag?
      # What we're doing here is starting at the start of the tag and
      # backtrack on all the whitespace until we land on something. If
      # that something is {% or %-, then we can safely assume that
      # we're inside a full tag and not a liquid tag.
      @inside_liquid_tag ||= if tag? && line_number && source
        i = 1
        i += 1 while source[start_index - i] =~ WHITESPACE && i < start_index
        first_two_backtracked_characters = source[(start_index - i - 1)..(start_index - i)]
        first_two_backtracked_characters != "{%" && first_two_backtracked_characters != "%-"
      else
        false
      end
    end

    # Is this node inside a tag or variable that starts by removing whitespace. i.e. {%- or {{-
    def whitespace_trimmed_start?
      @whitespace_trimmed_start ||= if line_number && source && !inside_liquid_tag?
        i = 1
        i += 1 while source[start_index - i] =~ WHITESPACE && i < start_index
        source[start_index - i] == "-"
      else
        false
      end
    end

    # Is this node inside a tag or variable ends starts by removing whitespace. i.e. -%} or -}}
    def whitespace_trimmed_end?
      @whitespace_trimmed_end ||= if line_number && source && !inside_liquid_tag?
        i = 0
        i += 1 while source[end_index + i] =~ WHITESPACE && i < source.size
        source[end_index + i] == "-"
      else
        false
      end
    end

    def range
      start = template.full_line(line_number).index(markup)
      [start, start + markup.length - 1]
    end

    def position
      @position ||= Position.new(
        markup,
        template&.source,
        line_number_1_indexed: line_number
      )
    end

    def start_token
      return "" if inside_liquid_tag?
      output = ""
      output += "{{" if variable?
      output += "{%" if tag?
      output += "-" if whitespace_trimmed_start?
      output
    end

    def end_token
      return "" if inside_liquid_tag?
      output = ""
      output += "-" if whitespace_trimmed_end?
      output += "}}" if variable?
      output += "%}" if tag?
      output
    end

    def start_index
      position.start_index
    end

    def end_index
      position.end_index
    end

    private

    # Here we're hacking around a glorious bug in Liquid that makes it so the
    # line_number and markup of a tag is wrong if there's whitespace
    # between the tag_name and the markup of the tag.
    #
    # {%
    #   render
    #   'foo'
    # %}
    #
    # Returns a raw value of "render 'foo'\n".
    # The "\n  " between render and 'foo' got replaced by a single space.
    #
    # And the line number is the one of 'foo'\n%}. Yay!
    #
    # This breaks any kind of position logic we have since that string
    # does not exist in the template.
    def tag_markup
      return @value.raw if @value.instance_variable_get('@markup').empty?
      return @tag_markup if @tag_markup

      l = 1
      scanner = StringScanner.new(source)
      scanner.scan_until(/\n/) while l < @value.line_number && (l += 1)
      start = scanner.charpos

      tag_markup = @value.instance_variable_get('@markup')

      # See https://github.com/Shopify/theme-check/pull/423/files#r701936559 for a detailed explanation
      # of why we're doing the check below.
      #
      # TL;DR it's because line_numbers are not enough to accurately
      # determine the position of the raw markup and because that
      # markup could be present on the same line outside of a Tag. e.g.
      #
      # uhoh {% if uhoh %}
      if (match = /#{@value.tag_name} +#{Regexp.escape(tag_markup)}/.match(source, start))
        return @tag_markup = match[0]
      end

      # find the markup
      markup_start = source.index(tag_markup, start)
      markup_end = markup_start + tag_markup.size

      # go back until you find the tag_name
      tag_start = markup_start
      tag_start -= 1 while source[tag_start - 1] =~ WHITESPACE
      tag_start -= @value.tag_name.size

      # keep track of the error in line_number
      @line_number_offset = source[tag_start...markup_start].count("\n")

      # return the real raw content
      @tag_markup = source[tag_start...markup_end]
    end
  end
end
