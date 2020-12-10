# frozen_string_literal: true
module ThemeCheck
  class MatchingSchemaTranslations < LiquidCheck
    severity :suggestion
    category :translation

    def initialize(default_locale: "en")
      # Strictly used to detect localized keys in the schema
      @default_locale = default_locale
    end

    def on_schema(node)
      schema = JSON.parse(node.value.nodelist.join)

      # Get all locales used in the schema
      used_locales = Set.new
      visit_locales(schema) do |_, locales|
        used_locales += locales
      end
      used_locales = used_locales.to_a

      # Check all used locales are defined in each localized keys
      visit_locales(schema) do |key, locales|
        missing = used_locales - locales
        if missing.any?
          add_offense("#{key} missing translations for #{missing.join(', ')}", node: node)
        end
      end
    rescue JSON::ParserError
      # Ignored, handled in ValidSchema.
    end

    private

    def visit_locales(object, top_path = [], &block)
      return unless object.is_a?(Hash)
      top_path += [object["id"]] if object["id"].is_a?(String)

      object.each_pair do |key, value|
        path = top_path + [key]

        case value
        when Array
          value.each do |item|
            visit_locales(item, path, &block)
          end

        when Hash
          # Localized key
          if value[@default_locale].is_a?(String)
            block.call(path.join("."), value.keys)
          # Nested keys
          else
            visit_locales(value, path, &block)
          end

        end
      end
    end
  end
end
