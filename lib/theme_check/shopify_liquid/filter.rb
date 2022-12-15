# frozen_string_literal: true
require 'yaml'

module ThemeCheck
  module ShopifyLiquid
    module Filter
      extend self

      LABELS_NOT_IN_SOURCE_INDEX = [
        "h",
        "installments_pricing",
        "sentence",
        "t",
        "app_block_path_for",
        "dev_shop?",
        "app_extension_path_for",
        "global_block_type?",
        "app_block_path?",
        "app_extension_path?",
        "app_snippet_path?",
        "registration_uuid_from",
        "handle_from",
        "camelcase",
        "format_code",
        "handle",
        "encode_url_component",
        "recover_password_link",
        "delete_customer_address_link",
        "edit_customer_address_link",
        "cancel_customer_order_link",
        "unit",
        "weight",
        "paragraphize",
        "excerpt",
        "pad_spaces",
        "distance_from",
        "theme_url",
        "link_to_theme",
        "_online_store_editor_live_setting",
        "debug",
      ]

      def labels
        @labels ||= SourceIndex.filters.map(&:name) + LABELS_NOT_IN_SOURCE_INDEX
      end
    end
  end
end
