# frozen_string_literal: true
module ThemeCheck
  module ParsingHelpers
    # Yield each chunk outside of "...", '...'
    def outside_of_strings(markup)
      scanner = StringScanner.new(markup)

      while scanner.scan(/.*?("|')/)
        yield scanner.matched[0..-2]
        quote = scanner.matched[-1] == "'" ? "'" : "\""
        # Skip to the end of the string
        # Check for empty string first, since follow regexp uses lookahead
        scanner.skip(/#{quote}/) || scanner.skip_until(/[^\\]#{quote}/)
      end

      yield scanner.rest if scanner.rest?
    end
  end
end
