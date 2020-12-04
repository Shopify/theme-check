# frozen_string_literal: true
module ThemeCheck
  module ChecksTracking
    def inherited(klass)
      Check.all << klass
    end
  end
end
