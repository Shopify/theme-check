# frozen_string_literal: true
module ThemeCheck
  #
  # Unwanted:
  #
  # {{ x | some_unknown_filter }}
  #
  # Wanted:
  #
  # {{ x | upcase }}
  #
  class UnknownFilter < Check
    severity :error

    def on_variable(node)
      used_filters = node.value.filters.map { |name, *_rest| name }
      undefined_filters = used_filters - LiquidAPI::Filters.labels

      undefined_filters.each do |undefined_filter|
        add_offense("Undefined filter `#{undefined_filter}`", node: node)
      end
    end
  end
end
