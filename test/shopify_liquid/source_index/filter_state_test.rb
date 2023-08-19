# frozen_string_literal: true

require 'test_helper'

module PlatformosCheck
  module ShopifyLiquid
    class SourceIndex
      class FilterStateTest < Minitest::Test
        def test_state_changes
          FilterState.mark_up_to_date
          refute(FilterState.outdated?)

          FilterState.mark_outdated
          assert(FilterState.outdated?)
        end
      end
    end
  end
end
