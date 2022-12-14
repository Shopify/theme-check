# frozen_string_literal: true

module ThemeCheck
  module LanguageServer
    module VariableLookupFinder
      module Constants
        ANY_STARTING_TAG = /\s*#{Liquid::AnyStartingTag}/
        ANY_ENDING_TAG = /#{Liquid::TagEnd}|#{Liquid::VariableEnd}\s*^/om

        UNCLOSED_SQUARE_BRACKET = /\[[^\]]*\Z/
        ENDS_IN_BRACKET_POSITION_THAT_CANT_BE_COMPLETED = %r{
          (
            # quotes not preceded by a [
            (?<!\[)['"]|
            # closing ]
            \]|
            # opening [
            \[
          )$
        }x

        VARIABLE_START = /\s*#{Liquid::VariableStart}/
        VARIABLE_LOOKUP_CHARACTERS = /[a-z0-9_.'"\]\[]/i
        VARIABLE_LOOKUP = /#{VARIABLE_LOOKUP_CHARACTERS}+/o
        SYMBOLS_PRECEDING_POTENTIAL_LOOKUPS = %r{
          (?:
            \s(?:
              if|elsif|unless|and|or|#{Liquid::Condition.operators.keys.join("|")}
              |echo
              |paginate
              |case|when
              |cycle
              |in
            )
            |[:,=]
          )
          \s+
        }omix
        ENDS_WITH_BLANK_POTENTIAL_LOOKUP = /#{SYMBOLS_PRECEDING_POTENTIAL_LOOKUPS}$/oimx
        ENDS_WITH_POTENTIAL_LOOKUP = /#{SYMBOLS_PRECEDING_POTENTIAL_LOOKUPS}#{VARIABLE_LOOKUP}$/oimx
      end
    end
  end
end
