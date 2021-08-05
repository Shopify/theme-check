# frozen_string_literal: true

module ThemeCheck
  class HtmlCheck < Check
    extend ChecksTracking
    START_OR_END_QUOTE = /(^['"])|(['"]$)/
  end
end
