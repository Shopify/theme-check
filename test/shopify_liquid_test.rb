# frozen_string_literal: true
require "test_helper"

module ThemeCheck
  class ShopifyLiquidTest < Minitest::Test
    def setup
      @expected_return_types = ShopifyLiquid::Object.drop_apis.keys + ['string', 'number', 'array']
    end

    def test_deprecated_filter_alternatives
      assert_equal(
        ['color_to_rgb', 'color_modify'].sort,
        ShopifyLiquid::DeprecatedFilter.alternatives('hex_to_rgba').sort,
      )

      assert_nil(ShopifyLiquid::DeprecatedFilter.alternatives('color_to_rgb'))
    end

    def test_filter_labels
      assert_equal(151, ShopifyLiquid::Filter.labels.size)
    end

    def test_object_labels
      assert_equal(80, ShopifyLiquid::Object.labels.size)
    end

    def test_attributes_by_labels_behaves_as_expected
      assert_includes(ShopifyLiquid::Object.attributes_by_label["image"], "aspect_ratio")
      refute_includes(ShopifyLiquid::Object.attributes_by_label["image"], "price")
      refute_includes(ShopifyLiquid::Object.attributes_by_label["product"], "aspect_ratio")
      assert_includes(ShopifyLiquid::Object.attributes_by_label["product"], "price")

      # strings have size properties
      assert_includes(ShopifyLiquid::Object.attributes_by_label["content_for_header"], "size")
      refute_includes(ShopifyLiquid::Object.attributes_by_label["content_for_header"], "aspect_ratio")

      # arrays have first, last, size properties
      assert_includes(ShopifyLiquid::Object.attributes_by_label["current_tags"], "size")
      assert_includes(ShopifyLiquid::Object.attributes_by_label["current_tags"], "first")
      assert_includes(ShopifyLiquid::Object.attributes_by_label["current_tags"], "last")
    end

    def test_object_return_types_exist
      ShopifyLiquid::Object.typed_labels.each do |_label, return_type|
        assert_return_type_exists(return_type)
      end
    end

    def assert_return_type_exists(return_type)
      return return_type.each { |t| assert_return_type_exists(t) } if return_type.is_a?(Array)
      assert_includes(@expected_return_types, return_type, "#{return_type} not in DropApis. Missing or typo?")
    end
  end
end
