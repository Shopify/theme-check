# frozen_string_literal: true
module ThemeCheck
  class RemoteAsset < LiquidCheck
    include RegexHelpers
    severity :suggestion
    categories :liquid, :performance
    doc docs_url(__FILE__)

    OFFENSE_MESSAGE = "Asset should be served by the Shopify CDN for better performance."

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

    RESOURCE_TAG = %r{<(?<tag_name>img|script|link|source)#{HTML_ATTRIBUTES}/?>}oim
    RESOURCE_URL = /\s(?:src|href)=(?<resource_url>#{QUOTED_LIQUID_ATTRIBUTE})/oim
    ASSET_URL_FILTER = /[\|\s]*(#{ASSET_URL_FILTERS.join('|')})/omi
    PROTOCOL = %r{(https?:)?//}
    ABSOLUTE_PATH = %r{\A/[^/]}im
    RELATIVE_PATH = %r{\A(?!#{PROTOCOL})[^/\{]}oim
    REL = /\srel=(?<rel>#{QUOTED_LIQUID_ATTRIBUTE})/oim

    def on_variable(node)
      record_variable_offense(node)
    end

    def on_document(node)
      source = node.template.source
      record_html_offenses(node, source)
    end

    private

    def record_variable_offense(variable_node)
      # We flag HTML tags with URLs not hosted by Shopify
      return if !html_resource_drop?(variable_node) || variable_hosted_by_shopify?(variable_node)
      add_offense(OFFENSE_MESSAGE, node: variable_node)
    end

    def html_resource_drop?(variable_node)
      variable_node.value.filters
        .any? { |(filter_name, *_filter_args)| HTML_FILTERS.include?(filter_name) }
    end

    def variable_hosted_by_shopify?(variable_node)
      variable_node.value.filters
        .any? { |(filter_name, *_filter_args)| ASSET_URL_FILTERS.include?(filter_name) }
    end

    # This part is slightly more complicated because we don't have an
    # HTML AST. We have to resort to looking at the HTML with regexes
    # to figure out if we have a resource (stylesheet, script, or media)
    # that points to a remote domain.
    def record_html_offenses(node, source)
      matches(source, RESOURCE_TAG).each do |match|
        tag = match[0]

        # We don't flag stuff without URLs
        next unless tag =~ RESOURCE_URL
        resource_match = Regexp.last_match
        resource_url = resource_match[:resource_url].gsub(START_OR_END_QUOTE, '')

        next if non_stylesheet_link?(tag)
        next if url_hosted_by_shopify?(resource_url)
        next if resource_url =~ ABSOLUTE_PATH
        next if resource_url =~ RELATIVE_PATH

        start = match.begin(0) + resource_match.begin(:resource_url)
        add_offense(
          OFFENSE_MESSAGE,
          node: node,
          markup: resource_url,
          line_number: source[0...start].count("\n") + 1,
        )
      end
    end

    def non_stylesheet_link?(tag)
      tag =~ REL && !(Regexp.last_match[:rel] =~ /\A['"]stylesheet['"]\Z/)
    end

    def url_hosted_by_shopify?(url)
      url =~ /\A#{VARIABLE}\Z/oim && url =~ ASSET_URL_FILTER
    end
  end
end
