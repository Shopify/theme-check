# frozen_string_literal: true
require 'yaml'

module ThemeCheck
  module ShopifyLiquid
    module Tag
      extend self

      def labels
        @tags ||= YAML.load(File.read("#{__dir__}/../../../data/shopify_liquid/tags.yml"))
          .to_set
      end

      def tag_regex(tag)
        return unless labels.include?(tag)
        @tag_regexes ||= {}
        @tag_regexes[tag] ||= /\A#{Liquid::TagStart}-?\s*#{tag}/m
      end

      def liquid_tag_regex(tag)
        return unless labels.include?(tag)
        @tag_liquid_regexes ||= {}
        @tag_liquid_regexes[tag] ||= /^\s*#{tag}/m
      end
    end
  end
end
