# frozen_string_literal: true

module ThemeCheck
  module LanguageServer
    module CodeActionHelper
      # @param offense [ThemeCheck::Offense]
      # @param range [Range]
      def offense_in_range?(offense, range)
        # Zero length ranges are OK and considered the same as size 1 ranges
        range = range.first...(range.first + 1) if range.size == 0 # rubocop:disable Style/ZeroLengthPredicate
        offense.range.cover?(range) || range.cover?(offense.range)
      end
    end
  end
end
