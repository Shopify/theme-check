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
        nodes
          .reject(&:nil?) # We don't want nil nodes, and they can happen
          .map { |node| LiquidNode.new(node, self, @theme_file) }
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

    # The original source code of the node. Does contain wrapping braces.
    def outer_markup
      if literal?
        markup
      elsif variable_lookup?
        ''
      elsif variable?
        start_token + markup + end_token
      elsif tag? && block?
        start_index = block_start_start_index
        end_index = block_start_end_index
        end_index += inner_markup.size
        end_index = find_block_delimiter(end_index)&.end(0)
        source[start_index...end_index]
      elsif tag?
        source[block_start_start_index...block_start_end_index]
      else
        inner_markup
      end
    end

    def inner_markup
      return '' unless block?

      @inner_markup ||= source[block_start_end_index...block_end_start_index]
    end

    def inner_json
      return nil unless schema?

      @inner_json ||= JSON.parse(inner_markup)
    rescue JSON::ParserError
      # Handled by ValidSchema
      @inner_json = nil
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

    def assigned_or_echoed_variable?
      variable? && start_token == ""
    end

    def variable_lookup?
      @value.is_a?(Liquid::VariableLookup)
    end

    # A {% comment %} block node?
    def comment?
      @value.is_a?(Liquid::Comment)
    end

    # {% # comment %}
    def inline_comment?
      @value.is_a?(Liquid::InlineComment)
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

    def schema?
      @value.is_a?(ThemeCheck::Tags::Schema)
    end

    # The `:under_score_name` of this type of node. Used to dispatch to the `on_<type_name>`
    # and `after_<type_name>` check methods.
    def type_name
      @type_name ||= StringHelpers.underscore(StringHelpers.demodulize(@value.class.name)).to_sym
    end

    def filters
      raise TypeError, "Attempting to lookup filters of #{type_name}. Only variables have filters." unless variable?

      @value.filters
    end

    def source
      theme_file&.source
    end

    # For debugging purposes, this might be easier for the eyes.
    def to_h
      if literal?
        return @value
      elsif variable_lookup?
        return {
          type_name: type_name,
          name: value.name.to_s,
          lookups: children.map(&:to_h),
        }
      end

      {
        type_name: type_name,
        markup: outer_markup,
        children: children.map(&:to_h),
      }
    end

    def block_start_markup
      source[block_start_start_index...block_start_end_index]
    end

    def block_start_start_index
      @block_start_start_index ||= if inside_liquid_tag?
        backtrack_on_whitespace(source, start_index, /[ \t]/)
      elsif tag?
        backtrack_on_whitespace(source, start_index) - start_token.length
      else
        position.start_index - start_token.length
      end
    end

    def block_start_end_index
      @block_start_end_index ||= position.end_index + end_token.size
    end

    def block_end_markup
      source[block_end_start_index...block_end_end_index]
    end

    def block_end_start_index
      return block_start_end_index unless tag? && block?

      @block_end_start_index ||= block_end_match&.begin(0) || block_start_end_index
    end

    def block_end_end_index
      return block_end_start_index unless tag? && block?

      @block_end_end_index ||= block_end_match&.end(0) || block_start_end_index
    end

    def outer_markup_start_index
      outer_markup_position.start_index
    end

    def outer_markup_end_index
      outer_markup_position.end_index
    end

    def outer_markup_start_row
      outer_markup_position.start_row
    end

    def outer_markup_start_column
      outer_markup_position.start_column
    end

    def outer_markup_end_row
      outer_markup_position.end_row
    end

    def outer_markup_end_column
      outer_markup_position.end_column
    end

    def inner_markup_start_index
      inner_markup_position.start_index
    end

    def inner_markup_end_index
      inner_markup_position.end_index
    end

    def inner_markup_start_row
      inner_markup_position.start_row
    end

    def inner_markup_start_column
      inner_markup_position.start_column
    end

    def inner_markup_end_row
      inner_markup_position.end_row
    end

    def inner_markup_end_column
      inner_markup_position.end_column
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
      if inside_liquid_tag?
        ""
      elsif variable? && source[start_index - 3..start_index - 1] == "{{-"
        "{{-"
      elsif variable? && source[start_index - 2..start_index - 1] == "{{"
        "{{"
      elsif tag? && whitespace_trimmed_start?
        "{%-"
      elsif tag?
        "{%"
      else
        ""
      end
    end

    def end_token
      if inside_liquid_tag? && source[end_index] == "\n"
        "\n"
      elsif inside_liquid_tag?
        ""
      elsif variable? && source[end_index...end_index + 3] == "-}}"
        "-}}"
      elsif variable? && source[end_index...end_index + 2] == "}}"
        "}}"
      elsif tag? && whitespace_trimmed_end?
        "-%}"
      elsif tag?
        "%}"
      else # this could happen because we're in an assign statement (variable)
        ""
      end
    end

    private

    def position
      @position ||= Position.new(
        markup,
        theme_file&.source,
        line_number_1_indexed: line_number
      )
    end

    def outer_markup_position
      @outer_markup_position ||= StrictPosition.new(
        outer_markup,
        source,
        block_start_start_index,
      )
    end

    def inner_markup_position
      @inner_markup_position ||= StrictPosition.new(
        inner_markup,
        source,
        block_start_end_index,
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

    # Returns the index of the leftmost consecutive whitespace
    # starting from start going backwards.
    #
    # e.g. backtrack_on_whitespace("01  45", 4) would return 2.
    # e.g. backtrack_on_whitespace("{%   render %}", 5) would return 2.
    def backtrack_on_whitespace(string, start, whitespace = WHITESPACE)
      i = start
      i -= 1 while string[i - 1] =~ whitespace && i > 0
      i
    end

    def find_block_delimiter(start_index)
      return nil unless tag? && block?

      tag_start, tag_end = if inside_liquid_tag?
        [
          /^\s*#{@value.tag_name}\s*/,
          /^\s*end#{@value.tag_name}\s*/,
        ]
      else
        [
          /#{Liquid::TagStart}-?\s*#{@value.tag_name}/mi,
          /#{Liquid::TagStart}-?\s*end#{@value.tag_name}\s*-?#{Liquid::TagEnd}/mi,
        ]
      end

      # This little algorithm below find the _correct_ block delimiter
      # (endif, endcase, endcomment) for the current tag. What do I
      # mean by correct? It means the one you'd expect. Making sure
      # that we don't do the naive regex find. Since you can have
      # nested ifs, fors, etc.
      #
      # It works by having a stack, pushing onto the stack when we
      # open a tag of our type_name. And popping when we find a
      # closing tag of our type_name.
      #
      # When the stack is empty, we return the end tag match.
      index = start_index
      stack = []
      stack.push("open")
      loop do
        tag_start_match = tag_start.match(source, index)
        tag_end_match = tag_end.match(source, index)

        return nil unless tag_end_match

        # We have found a tag_start and it appeared _before_ the
        # tag_end that we found, thus we push it onto the stack.
        if tag_start_match && tag_start_match.end(0) < tag_end_match.end(0)
          stack.push("open")
        end

        # We have found a tag_end, therefore we pop
        stack.pop

        # Nothing left on the stack, we're done.
        break tag_end_match if stack.empty?

        # We keep looking from the end of the end tag we just found.
        index = tag_end_match.end(0)
      end
    end

    def block_end_match
      @block_end_match ||= find_block_delimiter(block_start_end_index)
    end
  end
end
