# frozen_string_literal: true
module ThemeCheck
  # Reports errors when trying to use parser-blocking script tags
  class ParserBlockingJavaScript < LiquidCheck
    include RegexHelpers
    severity :error
    categories :liquid, :performance
    doc docs_url(__FILE__)

    PARSER_BLOCKING_SCRIPT_TAG = %r{
      <script                                    # Find the start of a script tag
      (?=[^>]+?src=)                             # Make sure src= is in the script with a lookahead
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

    def record_offenses_from_regex(regex: nil, message: nil)
      matches(@source, regex).each do |match|
        add_offense(
          message,
          node: @node,
          markup: match[0],
          line_number: @source[0...match.begin(0)].count("\n") + 1
        )
      end
    end
  end
end
