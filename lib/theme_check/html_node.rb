# frozen_string_literal: true
require "forwardable"

module ThemeCheck
  class HtmlNode < Node
    extend Forwardable
    include RegexHelpers
    include PositionHelper
    attr_reader :theme_file, :parent

    class << self
      include RegexHelpers

      def parse(liquid_file)
        placeholder_values = []
        parseable_source = +liquid_file.source.clone

        # Replace all non-empty liquid tags with ≬{i}######≬ to prevent the HTML
        # parser from freaking out. We transparently replace those placeholders in
        # HtmlNode.
        #
        # We're using base36 to prevent index bleeding on 36^3 tags.
        # `{{x}}` -> `≬#{i}≬` would properly be transformed for 46656 tags in a single file.
        # Should be enough.
        #
        # The base10 alternative would have overflowed at 1000 (`{{x}}` -> `≬1000≬`) which seemed more likely.
        #
        # Didn't go with base64 because of the `=` character that would have messed with HTML parsing.
        #
        # (Note, we're also maintaining newline characters in there so
        # that line numbers match the source...)
        matches(parseable_source, LIQUID_TAG_OR_VARIABLE).each do |m|
          value = m[0]
          next unless value.size > 4 # skip empty tags/variables {%%} and {{}}
          placeholder_values.push(value)
          key = (placeholder_values.size - 1).to_s(36)

          # Doing shenanigans so that line numbers match... Ugh.
          keyed_placeholder = parseable_source[m.begin(0)...m.end(0)]

          # First and last chars are ≬
          keyed_placeholder[0] = "≬"
          keyed_placeholder[-1] = "≬"

          # Non newline characters are #
          keyed_placeholder.gsub!(/[^\n≬]/, '#')

          # First few # are replaced by the base10 ID of the tag
          i = -1
          keyed_placeholder.gsub!('#') do
            i += 1
            if i > key.size - 1
              '#'
            else
              key[i]
            end
          end

          # Replace source by placeholder
          parseable_source[m.begin(0)...m.end(0)] = keyed_placeholder
        end

        new(
          Nokogiri::HTML5.fragment(parseable_source, max_tree_depth: 400, max_attributes: 400),
          liquid_file,
          placeholder_values,
          parseable_source
        )
      end
    end

    def initialize(value, theme_file, placeholder_values, parseable_source, parent = nil)
      @value = value
      @theme_file = theme_file
      @placeholder_values = placeholder_values
      @parseable_source = parseable_source
      @parent = parent
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

    def children
      @children ||= @value
        .children
        .map { |child| HtmlNode.new(child, theme_file, @placeholder_values, @parseable_source, self) }
    end

    def markup
      @markup ||= replace_placeholders(parseable_markup)
    end

    def line_number
      @value.line
    end

    def start_index
      position.start_index
    end

    def end_index
      position.end_index
    end

    def start_row
      position.start_row
    end

    def start_column
      position.start_column
    end

    def end_row
      position.end_row
    end

    def end_column
      position.end_column
    end

    def literal?
      @value.name == "text"
    end

    def element?
      @value.element?
    end

    def attributes
      @attributes ||= @value.attributes
        .map { |k, v| [replace_placeholders(k), replace_placeholders(v.value)] }
        .to_h
    end

    def parseable_markup
      return @parseable_source if @value.name == "#document-fragment"
      return @value.to_str if @value.comment?
      return @value.content if literal?

      start_index = from_row_column_to_index(@parseable_source, line_number - 1, 0)
      @parseable_source
        .match(/<\s*#{name}[^>]*>/im, start_index)[0]
    rescue NoMethodError
      # Don't know what's up with the following issue. Don't think
      # null check is correct approach. This should give us more info.
      # https://github.com/Shopify/theme-check/issues/528
      ThemeCheck.bug(<<~MSG)
        Can't find a parseable tag of name #{name} inside the parseable HTML.

        Tag name:
          #{@value.name.inspect}

        File:
          #{@theme_file.relative_path}

        Line number:
          #{line_number}

        Excerpt:
          ```
          #{@theme_file.source.lines[line_number - 1...line_number + 5].join("")}
          ```

        Parseable Excerpt:
          ```
          #{@parseable_source.lines[line_number - 1...line_number + 5].join("")}
          ```
      MSG
    end

    def content
      @content ||= replace_placeholders(@value.content)
    end

    def name
      if @value.name == "#document-fragment"
        "document"
      else
        @value.name
      end
    end

    private

    def position
      @position ||= Position.new(
        markup,
        theme_file.source,
        line_number_1_indexed: line_number,
      )
    end

    def replace_placeholders(string)
      # Replace all ≬{i}####≬ with the actual content.
      string.gsub(HTML_LIQUID_PLACEHOLDER) do |match|
        key = /[0-9a-z]+/.match(match.gsub("\n", ''))[0]
        @placeholder_values[key.to_i(36)]
      end
    end
  end
end
