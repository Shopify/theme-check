# frozen_string_literal: true
require "test_helper"

class ShopifyLiquidTest < Minitest::Test
  def test_filter_labels
    assert_equal(151, ThemeCheck::ShopifyLiquid::Filter.labels.size)
  end
end
