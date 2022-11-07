# frozen_string_literal: true

module ThemeCheck
  module LanguageServer
    module VariableLookupFinder
      ##
      # Attempt to turn the code of the token until the cursor position into
      # valid liquid code.
      #
      class LiquidFixer
        include Constants

        attr_reader :content, :cursor

        def initialize(content, cursor = nil)
          @content = content
          @cursor = cursor || content.size
        end

        def parsable
          # Welcome to Hackcity
          @markup = content[0...cursor]

          catch(:empty_lookup_markup) do
            # close open delimiters
            @markup += "'" if @markup.count("'").odd?
            @markup += '"' if @markup.count('"').odd?
            @markup += "]" if @markup =~ UNCLOSED_SQUARE_BRACKET

            @ends_with_blank_potential_lookup = @markup =~ ENDS_WITH_BLANK_POTENTIAL_LOOKUP
            @markup = last_line if liquid_tag?

            @markup = "{% #{@markup}" unless has_start_tag?

            # close the tag
            @markup += tag_end unless has_end_tag?

            # close if statements
            @markup += '{% endif %}' if tag?('if')

            # close unless statements
            @markup += '{% endunless %}' if tag?('unless')

            # close elsif statements
            @markup = "{% if x %}#{@markup}{% endif %}" if tag?('elsif')

            # close case statements
            @markup += '{% endcase %}' if tag?('case')

            # close when statements
            @markup = "{% case x %}#{@markup}{% endcase %}" if tag?('when')

            # close for statements
            @markup += '{% endfor %}' if tag?('for')

            # close tablerow statements
            @markup += '{% endtablerow %}' if tag?('tablerow')

            @markup
          end
        end

        private

        def tag?(tag_name)
          if @markup =~ tag_regex(tag_name)
            throw(:empty_lookup_markup, '') if @ends_with_blank_potential_lookup
            true
          else
            false
          end
        end

        def last_line
          lines = @markup.rstrip.lines

          last_line = lines.pop.lstrip while last_line.nil? || last_line =~ ANY_ENDING_TAG
          last_line
        end

        def liquid_tag?
          @markup =~ tag_regex('liquid')
        end

        def has_start_tag?
          @markup =~ ANY_STARTING_TAG
        end

        def has_end_tag?
          @markup =~ ANY_ENDING_TAG
        end

        def tag_end
          @markup =~ VARIABLE_START ? ' }}' : ' %}'
        end

        def tag_regex(tag_name)
          ShopifyLiquid::Tag.tag_regex(tag_name)
        end
      end
    end
  end
end
