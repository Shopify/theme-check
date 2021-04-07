# frozen_string_literal: true

module ThemeCheck
  module LanguageServer
    module VariableLookupFinder
      extend self

      UNCLOSED_SQUARE_BRACKET = /\[[^\]]*\Z/
      UNCLOSED_SINGLE_QUOTE = /'[^']*\Z/
      UNCLOSED_DOUBLE_QUOTE = /"[^"]*\Z/

      def lookup(content, cursor)
        potential_lookup = lookup_liquid_variable(content, cursor) || lookup_liquid_tag(content, cursor)

        # And we only return it if it's parsed by Liquid as VariableLookup
        return unless potential_lookup.is_a?(Liquid::VariableLookup)
        potential_lookup
      end

      private

      def cursor_is_on_liquid_variable_lookup_position(content, cursor)
        previous_char = content[cursor - 1]
        is_liquid_variable = content =~ Liquid::VariableStart
        is_in_variable_segment = previous_char =~ /[a-z0-9_.'"-]/i
        is_on_blank_variable_lookup_position = content[0..cursor - 1] =~ /[{:,]\s+$/
        (
          is_liquid_variable && (
            is_in_variable_segment ||
            is_on_blank_variable_lookup_position
          )
        )
      end

      def lookup_liquid_variable(content, cursor)
        return unless cursor_is_on_liquid_variable_lookup_position(content, cursor)
        start_index = 2
        end_index = cursor - 1

        # We take the following content
        # - start after the first two {{
        # - end at cursor position
        #
        # That way, we'll have a partial liquid variable that
        # can be parsed such that the "last" variable_lookup
        # will be the one we're trying to complete.
        markup = content[start_index..end_index]

        # Early return for incomplete variables
        return empty_lookup if markup =~ /\s+$/
        return if markup =~ /((?<!\[)['"]|\]|\[)$/

        # Now we go to hack city... The cursor might be in the middle
        # of a string/square bracket lookup. We need to close those
        # otherwise the variable parse won't work.
        markup += "'" if markup.count("'").odd?
        markup += '"' if markup.count('"').odd?
        markup += "]" if markup =~ UNCLOSED_SQUARE_BRACKET

        variable = variable_from_markup(markup)

        variable_lookup_for_liquid_variable(variable)
      end

      ENDS_WITH_POTENTIAL_LOOKUP_POSITION = %r{
        (
          \s(
            if|elsif|unless|and|or|#{Liquid::Condition.operators.keys.join("|")}
            |echo
            |case|when
            |in
          )
          |[:,=]
        )
        \s+$
      }oimx

      def cursor_is_on_liquid_tag_lookup_position(content, cursor)
        previous_char = content[cursor - 1]
        is_liquid_tag = content.match?(Liquid::TagStart)
        is_in_variable_segment = previous_char =~ /[a-z0-9_.'"-]/i
        is_on_blank_variable_lookup_position = content[0..cursor - 1] =~ ENDS_WITH_POTENTIAL_LOOKUP_POSITION
        (
          is_liquid_tag && (
            is_in_variable_segment ||
            is_on_blank_variable_lookup_position
          )
        )
      end

      def lookup_liquid_tag(content, cursor)
        return unless cursor_is_on_liquid_tag_lookup_position(content, cursor)

        start_index = 0
        end_index = cursor - 1
        markup = content[start_index..end_index]
        last_line = markup.rstrip.lines.last

        is_liquid_tag = markup =~ /\A{%\s*liquid/im
        ends_with_spaces = markup =~ / +$/
        ends_with_potential_lookup_position = markup =~ ENDS_WITH_POTENTIAL_LOOKUP_POSITION

        # Welcome to Hackcity
        markup += "'" if markup.count("'").odd?
        markup += '"' if markup.count('"').odd?
        markup += "]" if markup =~ UNCLOSED_SQUARE_BRACKET
        markup += ' %}' unless is_liquid_tag
        markup = "{% liquid \n#{last_line}" if is_liquid_tag

        # if statements
        is_if_tag = markup =~ /\A{%\s*if/im
        is_liquid_if = is_liquid_tag && last_line.match?(/^\s*if/)
        return empty_lookup if (is_if_tag || is_liquid_if) && ends_with_spaces
        markup += '{% endif %}' if is_if_tag
        markup += "\n endif" if is_liquid_if

        # unless statements
        is_liquid_unless = is_liquid_tag && last_line.match?(/^\s*unless/)
        is_unless_tag = markup =~ /\A{%\s*unless/im
        return empty_lookup if (is_unless_tag || is_liquid_unless) && ends_with_spaces
        markup += '{% endunless %}' if is_unless_tag
        markup += "\n endunless" if is_liquid_unless

        # elsif statements
        is_elsif_tag = markup =~ /\A{%\s*elsif/im
        is_liquid_elsif = is_liquid_tag && last_line.match?(/\A\s*elsif/)
        return empty_lookup if (is_elsif_tag || is_liquid_elsif) && ends_with_spaces
        markup = '{% if x %}' + markup + '{% endif %}' if is_elsif_tag
        if is_liquid_elsif
          markup = <<~LIQUID
            {% liquid
              if x
              #{markup.lines[-1]}
              endif
          LIQUID
        end

        # case statements
        is_case_tag = markup =~ /\A{%\s*case/im
        is_liquid_case = is_liquid_tag && last_line.match?(/^\s*case/)
        return empty_lookup if (is_case_tag || is_liquid_case) && ends_with_spaces
        markup += "{% endcase %}" if is_case_tag
        markup += "\n endcase" if is_liquid_case

        # when
        is_when_tag = markup =~ /\A{%\s*when/im
        is_liquid_when = is_liquid_tag && last_line.match?(/^\s*when/)
        return empty_lookup if (is_when_tag || is_liquid_when) && ends_with_spaces
        markup = "{% case x %}" + markup + "{% endcase %}" if markup =~ /\A{%\s*when/im
        markup = "{% liquid\n case x\n #{last_line}\n endcase\n" if is_liquid_when

        # for statements
        is_for_tag = markup =~ /\A{%\s*for/im
        is_liquid_for = is_liquid_tag && last_line.match?(/^\s*(for)/)
        return empty_lookup if (is_for_tag || is_liquid_for) && ends_with_potential_lookup_position
        markup += "{% endfor %}" if is_for_tag
        markup += "\n endfor" if is_liquid_for

        # closing liquid tag
        markup += "\n%}" if is_liquid_tag

        template = Liquid::Template.parse(markup)
        current_tag = template.root.nodelist[0]

        case current_tag.tag_name
        when "if", "unless"
          variable_lookup_for_if_tag(current_tag)
        when "case"
          variable_lookup_for_case_tag(current_tag)
        when "cycle"
          variable_lookup_for_cycle_tag(current_tag)
        when "for"
          variable_lookup_for_for_tag(current_tag)
        when "render"
          variable_lookup_for_render_tag(current_tag)
        when "assign"
          variable_lookup_for_assign_tag(current_tag)
        when "echo"
          variable_lookup_for_echo_tag(current_tag)
        end

      # rubocop:disable Style/RedundantReturn
      rescue Liquid::SyntaxError
        # We don't complete variable for liquid syntax errors
        return
      end
      # rubocop:enable Style/RedundantReturn

      def variable_lookup_for_if_tag(if_tag)
        condition = if_tag.blocks.last
        variable_lookup_for_condition(condition)
      end

      def variable_lookup_for_condition(condition)
        return variable_lookup_for_condition(condition.child_condition) if condition.child_condition
        return condition.right if condition.right
        condition.left
      end

      def variable_lookup_for_case_tag(case_tag)
        return variable_lookup_for_case_block(case_tag.blocks.last) unless case_tag.blocks.empty?
        case_tag.left
      end

      def variable_lookup_for_case_block(condition)
        condition.right
      end

      def variable_lookup_for_cycle_tag(cycle_tag)
        cycle_tag.variables.last
      end

      def variable_lookup_for_for_tag(for_tag)
        for_tag.collection_name
      end

      def variable_lookup_for_render_tag(render_tag)
        return empty_lookup if render_tag.raw =~ /:\s*$/
        render_tag.attributes.values.last
      end

      def variable_lookup_for_assign_tag(assign_tag)
        variable_lookup_for_liquid_variable(assign_tag.from)
      end

      def variable_lookup_for_echo_tag(echo_tag)
        variable_lookup_for_liquid_variable(echo_tag.variable)
      end

      def variable_lookup_for_liquid_variable(variable)
        has_filters = !variable.filters.empty?

        # Can complete after trailing comma or :
        if has_filters && variable.raw =~ /[:,]\s*$/
          empty_lookup
        elsif has_filters
          last_filter_argument(variable.filters)
        elsif variable.name.nil?
          empty_lookup
        else
          variable.name
        end
      end

      def empty_lookup
        Liquid::VariableLookup.parse('')
      end

      # We want the last thing in variable.filters which is at most
      # an array that looks like [name, positional_args, hash_arg]
      def last_filter_argument(filters)
        filter = filters.last
        return filter[2].values.last if filter.size == 3
        return filter[1].last if filter.size == 2
        nil
      end

      def variable_from_markup(markup, parse_context = Liquid::ParseContext.new)
        Liquid::Variable.new(markup, parse_context)
      end
    end
  end
end
