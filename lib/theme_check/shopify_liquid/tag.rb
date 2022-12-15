# frozen_string_literal: true
require 'yaml'

module ThemeCheck
  module ShopifyLiquid
    module Tag
      extend self

      LABELS_NOT_IN_SOURCE_INDEX = ["elsif", "ifchanged", { "schema" => "endschema" }, "when"]

      def labels
        @labels ||= tags_file_contents
          .map { |x| to_label(x) }
          .to_set
      end

      def end_labels
        @end_labels ||= tags_file_contents
          .select { |x| x.is_a?(Hash) }
          .map { |x| x.values[0] }
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

      private

      def to_label(label)
        return label if label.is_a?(String)
        label.keys[0]
      end

      def tags_file_contents
        @tags_file_contents ||= SourceIndex.tags.map do |tag|
          opening_tag = tag.name
          closing_tag = "end#{opening_tag}"
          if tag.hash['syntax'] =~ /#{opening_tag}.+#{closing_tag}/m
            { opening_tag => closing_tag }
          else
            opening_tag
          end
        end + LABELS_NOT_IN_SOURCE_INDEX
      end
    end
  end
end
