# frozen_string_literal: true
require 'yaml'

module ThemeCheck
  module ShopifyLiquid
    module Tag
      extend self

      def labels
        @labels ||= tags_file_contents
          .map { |x| to_label(x) }
      end

      def end_labels
        @end_labels ||= tags_file_contents
          .select { |x| x.is_a?(Hash) }
          .map { |x| x.values[0] }
      end

      private

      def to_label(label)
        return label if label.is_a?(String)
        label.keys[0]
      end

      def tags_file_contents
        @tags_file_contents ||= YAML.load(File.read("#{__dir__}/../../../data/shopify_liquid/tags.yml"))
      end
    end
  end
end
