# frozen_string_literal: true

module ThemeCheck
  module RegexHelpers
    def matches(s, re)
      start_at = 0
      matches = []
      while (m = s.match(re, start_at))
        matches.push(m)
        start_at = m.end(0)
      end
      matches
    end
  end
end
