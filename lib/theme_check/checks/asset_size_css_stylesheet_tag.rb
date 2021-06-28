# frozen_string_literal: true
module ThemeCheck
  class AssetSizeCSSStylesheetTag < LiquidCheck
    include RegexHelpers
    severity :error
    category :liquid, :performance
    doc docs_url(__FILE__)

    def initialize(threshold_in_bytes: 100_000)
      @threshold_in_bytes = threshold_in_bytes
    end

    def on_variable(node)
      used_filters = node.value.filters.map { |name, *_rest| name }
      return unless used_filters.include?("stylesheet_tag")
      file_size = href_to_file_size('{{' + node.markup + '}}')
      return if file_size <= @threshold_in_bytes
      add_offense(
        "CSS on every page load exceeding compressed size threshold (#{@threshold_in_bytes} Bytes).",
        node: node
      )
    end
  end
end
