# frozen_string_literal: true
module ThemeCheck
  module ShopifyLiquid
    module SystemTranslations
      extend self

      def translations
        @translations ||= YAML.load(File.read("#{__dir__}/../../../data/shopify_translation_keys.yml")).to_set
      end

      def translations_hash
        @translations_hash ||= translations.reduce({}) do |acc, k|
          dig_set(acc, k.split('.'), "")
        end
      end

      def include?(key)
        translations.include?(key)
      end

      private

      def dig_set(obj, keys, value)
        key = keys.first
        if keys.length == 1
          obj[key] = value
        else
          obj[key] = {} unless obj[key]
          dig_set(obj[key], keys.slice(1..-1), value)
        end
        obj
      end
    end
  end
end
