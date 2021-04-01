# frozen_string_literal: true
require 'yaml'

module ThemeCheck
  module ShopifyLiquid
    module Object
      extend self

      BASIC_TYPES = [
        'array',
        'boolean',
        'nil',
        'number',
        'string',
      ]

      def typed_labels
        @typed_labels ||= YAML.load(File.read("#{__dir__}/../../../data/shopify_liquid/objects.yml"))
      end

      def labels
        @labels ||= typed_labels.keys
      end

      def plus_labels
        @plus_labels ||= YAML.load(File.read("#{__dir__}/../../../data/shopify_liquid/plus_objects.yml"))
      end

      def drop_apis
        @drop_apis ||= YAML.load(File.read("#{__dir__}/../../../data/shopify_liquid/drop_apis.yml"))
          .map { |drop_api| [drop_api["drop"], drop_api["attributes"]] }
          .to_h
      end

      def attributes_by_label
        @attributes_by_label ||= typed_labels
          .map { |name, output_type| [name, attributes_for_output_type(output_type)] }
          .to_h
      end

      private

      def attributes_for_output_type(output_type)
        if output_type.is_a?(Array)
          output_type
            .flat_map { |r| attributes_for_output_type(r) }
            .uniq
        elsif output_type.is_a?(String) && !BASIC_TYPES.include?(output_type)
          drop_apis[output_type]
        elsif output_type == 'array'
          ['first', 'size', 'last']
        elsif output_type == 'string'
          ['size']
        else
          []
        end
      end
    end
  end
end
