# frozen_string_literal: true

module ThemeCheck
  module LanguageServer
    module TypeHelper
      def input_type_of(literal)
        case literal
        when String
          'string'
        when Numeric
          'number'
        when TrueClass, FalseClass
          'boolean'
        when NilClass
          'nil'
        else
          'untyped'
        end
      end
    end
  end
end
