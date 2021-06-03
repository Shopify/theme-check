# frozen_string_literal: true
module ThemeCheck
  class AssetUrlFilters < LiquidCheck
    severity :suggestion
    categories :liquid, :performance
    doc docs_url(__FILE__)

    HTML_FILTERS = [
      'stylesheet_tag',
      'script_tag',
      'img_tag',
    ]
    ASSET_URL_FILTERS = [
      'asset_url',
      'asset_img_url',
      'file_img_url',
      'file_url',
      'global_asset_url',
      'img_url',
      'payment_type_img_url',
      'shopify_asset_url',
    ]

    def on_variable(node)
      record_variable_offense(node)
    end

    private

    def record_variable_offense(variable_node)
      # We flag HTML tags with URLs not hosted by Shopify
      return if !html_resource_drop?(variable_node) || variable_hosted_by_shopify?(variable_node)
      add_offense("Use one of the asset_url filters to serve assets", node: variable_node)
    end

    def html_resource_drop?(variable_node)
      variable_node.value.filters
        .any? { |(filter_name, *_filter_args)| HTML_FILTERS.include?(filter_name) }
    end

    def variable_hosted_by_shopify?(variable_node)
      variable_node.value.filters
        .any? { |(filter_name, *_filter_args)| ASSET_URL_FILTERS.include?(filter_name) }
    end
  end
end
