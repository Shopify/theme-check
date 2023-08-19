# frozen_string_literal: true

require 'test_helper'

module PlatformosCheck
  module ShopifyLiquid
    class SourceIndex
      class ObjectStateTest < Minitest::Test
        def test_state_changes
          ObjectState.mark_up_to_date
          refute(ObjectState.outdated?)

          ObjectState.mark_outdated
          assert(ObjectState.outdated?)
        end
      end
    end
  end
end
