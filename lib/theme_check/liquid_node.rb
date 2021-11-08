# frozen_string_literal: true

module ThemeCheck
  # A node from the Liquid AST, the result of parsing a liquid file.
  class LiquidNode < Node
    attr_reader :value, :parent, :theme_file

    def initialize(value, parent, theme_file)
      raise ArgumentError, "Expected a Liquid AST Node" if value.is_a?(LiquidNode)
      @value = value
      @parent = parent
      @theme_file = theme_file
      @tag_markup = nil
      @line_number_offset = 0
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
        nodes.map { |node| LiquidNode.new(node, self, @theme_file) }
      end
    end

    # The original source code of the node. Doesn't contain wrapping braces.
    def markup
      if tag?
        tag_markup
      elsif literal?
        value.to_s
      elsif @value.instance_variable_defined?(:@markup)
        @value.instance_variable_get(:@markup)
      end
    end

    def markup=(markup)
      if @value.instance_variable_defined?(:@markup)
        @value.instance_variable_set(:@markup, markup)
      end
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

    def start_index
      position.start_index
    end

    def start_row
      position.start_row
    end

    def start_column
      position.start_column
    end

    def end_index
      position.end_index
    end

    def end_row
      position.end_row
    end

    def end_column
      position.end_column
    end

    def start_token_index
      return position.start_index if inside_liquid_tag?
      position.start_index - (start_token.length + 1)
    end

    def end_token_index
      return position.end_index if inside_liquid_tag?
      position.end_index + end_token.length
    end

    # Literals are hard-coded values in the liquid file.
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

    # Top level node of every liquid_file.
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

    # The `:under_score_name` of this type of node. Used to dispatch to the `on_<type_name>`
    # and `after_<type_name>` check methods.
    def type_name
      @type_name ||= StringHelpers.underscore(StringHelpers.demodulize(@value.class.name)).to_sym
    end

    def source
      theme_file&.source
    end

    def block_body
      return unless block_tag?
      @block_body ||= source[block_body_start_index...block_body_end_index]
    end

    def block_body_start_index
      return unless block_tag?
      @block_body_start_index ||= source.match(/-?#{Liquid::TagEnd}/omi, end_index).end(0)
    end

    def block_body_end_index
      return unless block_tag?
      @block_body_end_index ||= source.index(/#{Liquid::TagStart}-?\s*#{@value.block_delimiter}/im, block_body_start_index)
    end

    def block_body_start_row
      block_body_position&.start_row
    end

    def block_body_start_column
      block_body_position&.start_column
    end

    def block_body_end_row
      block_body_position&.end_row
    end

    def block_body_end_column
      block_body_position&.end_column
    end

    WHITESPACE = /\s/

    # Is this node inside a `{% liquid ... %}` block?
    def inside_liquid_tag?
      # What we're doing here is starting at the start of the tag and
      # backtrack on all the whitespace until we land on something. If
      # that something is {% or %-, then we can safely assume that
      # we're inside a full tag and not a liquid tag.
      @inside_liquid_tag ||= if tag? && start_index && source
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
      @whitespace_trimmed_start ||= if start_index && source && !inside_liquid_tag?
        i = 1
        i += 1 while source[start_index - i] =~ WHITESPACE && i < start_index
        source[start_index - i] == "-"
      else
        false
      end
    end

    # Is this node inside a tag or variable ends starts by removing whitespace. i.e. -%} or -}}
    def whitespace_trimmed_end?
      @whitespace_trimmed_end ||= if end_index && source && !inside_liquid_tag?
        i = 0
        i += 1 while source[end_index + i] =~ WHITESPACE && i < source.size
        source[end_index + i] == "-"
      else
        false
      end
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

    private

    def position
      @position ||= Position.new(
        markup,
        theme_file&.source,
        line_number_1_indexed: line_number
      )
    end

    def block_body_position
      return unless block_tag?
      @block_body_position ||= StrictPosition.new(
        block_body,
        source,
        block_body_start_index,
      )
    end

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
    # does not exist in the theme_file.
    def tag_markup
      return @tag_markup if @tag_markup

      l = 1
      scanner = StringScanner.new(source)
      scanner.scan_until(/\n/) while l < @value.line_number && (l += 1)
      start = scanner.charpos

      tag_name = @value.tag_name
      tag_markup = @value.instance_variable_get('@markup')

      # This is tricky, if the tag_markup is empty, then the tag could
      # either start on a previous line, or the tag could start on the
      # same line.
      #
      # Consider this:
      # 1 {%
      # 2 comment
      # 3 %}{% endcomment %}{%comment%}
      #
      # Both comments would markup == "" AND line_number == 3
      #
      # There's no way to determine which one is the correct one, but
      # we'll try our best to at least give you one.
      #
      # To screw with you even more, the name of the tag could be
      # outside of a tag on the same line :) But I won't do anything
      # about that (yet?).
      #
      # {% comment
      # %}comment{% endcomment %}
      if tag_markup.empty?
        eol = source.index("\n", start) || source.size

        # OK here I'm trying one of two things. Either tag_start is on
        # the same line OR tag_start is on a previous line. The line
        # number would be at the end of the whitespace after tag_name.
        unless (tag_start = source.index(tag_name, start)) && tag_start < eol
          tag_start = start
          tag_start -= 1 while source[tag_start - 1] =~ WHITESPACE
          tag_start -= @value.tag_name.size

          # keep track of the error in line_number
          @line_number_offset = source[tag_start...start].count("\n")
        end
        tag_end = tag_start + tag_name.size
        tag_end += 1 while source[tag_end] =~ WHITESPACE

        # return the real raw content
        @tag_markup = source[tag_start...tag_end]
        return @tag_markup

      # See https://github.com/Shopify/theme-check/pull/423/files#r701936559 for a detailed explanation
      # of why we're doing the check below.
      #
      # TL;DR it's because line_numbers are not enough to accurately
      # determine the position of the raw markup and because that
      # markup could be present on the same line outside of a Tag. e.g.
      #
      # uhoh {% if uhoh %}
      elsif (match = /#{tag_name} +#{Regexp.escape(tag_markup)}/.match(source, start))
        return @tag_markup = match[0]
      end

      # find the markup
      markup_start = source.index(tag_markup, start)
      markup_end = markup_start + tag_markup.size

      # go back until you find the tag_name
      tag_start = markup_start
      tag_start -= 1 while source[tag_start - 1] =~ WHITESPACE
      tag_start -= tag_name.size

      # keep track of the error in line_number
      @line_number_offset = source[tag_start...markup_start].count("\n")

      # return the real raw content
      @tag_markup = source[tag_start...markup_end]
    end
  end
end
