# frozen_string_literal: true

module ThemeCheck
  module StringHelpers
    extend self

    # Removes the module part from the expression in the string.
    # Ported from ActiveSupport
    #
    #   demodulize('ActiveSupport::Inflector::Inflections') # => "Inflections"
    #   demodulize('Inflections')                           # => "Inflections"
    #   demodulize('::Inflections')                         # => "Inflections"
    #   demodulize('')                                      # => ""
    #
    # See also #deconstantize.
    def demodulize(path)
      path = path.to_s
      if (i = path.rindex("::"))
        path[(i + 2)..-1]
      else
        path
      end
    end

    # Makes an underscored, lowercase form from the expression in the string.
    # Base on ActiveSupport's
    #
    # Changes '::' to '/' to convert namespaces to paths.
    #
    #   underscore('ActiveModel')         # => "active_model"
    #   underscore('ActiveModel::Errors') # => "active_model/errors"
    #
    # As a rule of thumb you can think of +underscore+ as the inverse of
    # #camelize, though there are cases where that does not hold:
    #
    #   camelize(underscore('SSLError'))  # => "SslError"
    def underscore(camel_cased_word)
      return camel_cased_word unless /[A-Z-]|::/.match?(camel_cased_word)
      word = camel_cased_word.to_s.gsub("::", "/")
      word.gsub!(/([A-Z\d]+)([A-Z][a-z])/, '\1_\2')
      word.gsub!(/([a-z\d])([A-Z])/, '\1_\2')
      word.tr!("-", "_")
      word.downcase!
      word
    end
  end
end
