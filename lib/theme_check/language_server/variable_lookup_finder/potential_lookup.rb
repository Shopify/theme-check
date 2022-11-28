# frozen_string_literal: true

module ThemeCheck
  module LanguageServer
    module VariableLookupFinder
      class PotentialLookup < Struct.new(:name, :lookups, :scope)
      end
    end
  end
end
