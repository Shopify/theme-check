# frozen_string_literal: true
require "test_helper"

class LiquidAPITest < Minitest::Test
  def test_filter_labels
    assert_equal(151, LiquidAPI::Filters.labels.size)
  end
end
