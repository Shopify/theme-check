# frozen_string_literal: true
module PlatformosCheck
  module ChecksTracking
    def inherited(klass)
      Check.all << klass
    end
  end
end
