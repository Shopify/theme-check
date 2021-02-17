# frozen_string_literal: true
require 'yaml'

module ThemeCheck
  module ShopifyLiquid
    module Tag
      extend self

      def labels
        @tags ||= begin
          YAML.load(File.read("#{__dir__}/../../../data/shopify_liquid/tags.yml"))
        end
      end
    end
  end
end
