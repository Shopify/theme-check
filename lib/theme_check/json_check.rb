# frozen_string_literal: true

module ThemeCheck
  class JsonCheck < Check
    extend ChecksTracking

    def add_offense(message, markup: nil, line_number: nil, theme_file: nil, &block)
      offenses << Offense.new(check: self, message: message, markup: markup, line_number: line_number, theme_file: theme_file, correction: block)
    end
  end
end
