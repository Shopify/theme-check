# frozen_string_literal: true

module ThemeCheck
  module RegexHelpers
    LIQUID_TAG = /#{Liquid::TagStart}.*?#{Liquid::TagEnd}/om
    LIQUID_VARIABLE = /#{Liquid::VariableStart}.*?#{Liquid::VariableEnd}/om
    LIQUID_TAG_OR_VARIABLE = /#{LIQUID_TAG}|#{LIQUID_VARIABLE}/om
    HTML_LIQUID_PLACEHOLDER = /≬[0-9a-z\n]+[#\n]*≬/m
    START_OR_END_QUOTE = /(^['"])|(['"]$)/

    def matches(s, re)
      start_at = 0
      matches = []
      while (m = s.match(re, start_at))
        matches.push(m)
        start_at = m.end(0)
      end
      matches
    end

    def replace_liquid_source_with_html_placeholders(source)
      placeholder_values = []
      parseable_source = +source.clone

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

      [parseable_source, placeholder_values]
    end

    def replace_parseable_source_placeholders(string, placeholder_values)
      # Replace all ≬{i}####≬ with the actual content.
      string.gsub(HTML_LIQUID_PLACEHOLDER) do |match|
        key = /[0-9a-z]+/.match(match.gsub("\n", ''))[0]
        placeholder_values[key.to_i(36)]
      end
    end
  end
end
