# frozen_string_literal: true

module ThemeCheck
  module ShopifyLiquid
    class SourceIndex
      class BaseState
        class << self
          def mark_outdated
            @up_to_date = false
          end

          def mark_up_to_date
            @up_to_date = true
          end

          def outdated?
            @up_to_date == false
          end
        end
      end
    end
  end
end
