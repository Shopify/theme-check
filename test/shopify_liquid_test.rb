# frozen_string_literal: true
require "test_helper"

class ShopifyLiquidTest < Minitest::Test
  def test_deprecated_filter_alternatives
    assert_equal(
      ['color_to_rgb', 'color_modify'].sort,
      PlatformosCheck::ShopifyLiquid::DeprecatedFilter.alternatives('hex_to_rgba').sort,
    )

    assert_nil(PlatformosCheck::ShopifyLiquid::DeprecatedFilter.alternatives('color_to_rgb'))
  end

  def test_filter_labels
    assert_operator(PlatformosCheck::ShopifyLiquid::Filter.labels.size, :>=, 169)
  end

  def test_object_labels
    assert_operator(PlatformosCheck::ShopifyLiquid::Object.labels.size, :>=, 119)
  end
end
