# frozen_string_literal: true
module ThemeCheck
  module ParsingHelpers
    # Yield each chunk outside of "...", '...'
    def outside_of_strings(markup)
      scanner = StringScanner.new(markup)

      while scanner.scan(/.*?("|')/)
        yield scanner.matched[0..-2]
        # Skip to the end of the string
        scanner.skip_until(scanner.matched[-1] == "'" ? /[^\\]'/ : /[^\\]"/)
      end

      yield scanner.rest if scanner.rest?
    end
  end
end
