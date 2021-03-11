# frozen_string_literal: true
module ThemeCheck
  # Reports errors when trying to use parser-blocking script tags
  class ParserBlockingJavaScript < LiquidCheck
    severity :error
    categories :liquid, :performance
    doc docs_url("docs/checks/parser_blocking_javascript.md")

    PARSER_BLOCKING_SCRIPT_TAG = %r{
      <script                                    # Find the start of a script tag
      (?=(?:[^>]|\n|\r)+?src=)+?                 # Make sure src= is in the script with a lookahead
      (?:(?!defer|async|type=["']module['"]).)*? # Find tags that don't have defer|async|type="module"
      >
    }xim
    SCRIPT_TAG_FILTER = /\{\{[^}]+script_tag\s+\}\}/

    def on_document(node)
      @source = node.template.source
      @node = node
      record_offenses
    end

    private

    def record_offenses
      record_offenses_from_regex(
        message: "Missing async or defer attribute on script tag",
        regex: PARSER_BLOCKING_SCRIPT_TAG,
      )
      record_offenses_from_regex(
        message: "The script_tag filter is parser-blocking. Use a script tag with the async or defer attribute for better performance",
        regex: SCRIPT_TAG_FILTER,
      )
    end

    # The trickiness here is matching on scripts that are defined on
    # multiple lines (or repeat matches). This makes the line_number
    # calculation a bit weird. So instead, we traverse the string in
    # a very imperative way.
    def record_offenses_from_regex(regex: nil, message: nil)
      i = 0
      while (i = @source.index(regex, i))
        script = @source.match(regex, i)[0]

        add_offense(
          message,
          node: @node,
          markup: script,
          line_number: @source[0...i].count("\n") + 1
        )

        i += script.size
      end
    end
  end
end
