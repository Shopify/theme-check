# frozen_string_literal: true
module ThemeCheck
  module ParsingHelpers
    # Yield each chunk outside of "...", '...'
    def outside_of_strings(markup)
      scanner = StringScanner.new(markup)

      while scanner.scan(/.*?("|')/m)
        chunk_start = scanner.pre_match.size
        yield scanner.matched[0..-2], chunk_start
        quote = scanner.matched[-1] == "'" ? "'" : "\""
        # Skip to the end of the string
        # Check for empty string first, since follow regexp uses lookahead
        scanner.skip(/#{quote}/) || scanner.skip_until(/[^\\]#{quote}/)
      end

      yield scanner.rest, scanner.charpos if scanner.rest?
    end
  end
end
