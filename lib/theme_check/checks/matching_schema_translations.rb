# frozen_string_literal: true
module ThemeCheck
  class MatchingSchemaTranslations < LiquidCheck
    severity :suggestion
    category :translation
    doc docs_url(__FILE__)

    def on_schema(node)
      schema = JSON.parse(node.value.nodelist.join)

      # Get all locales used in the schema
      used_locales = Set.new([theme.default_locale])
      visit_object(schema) do |_, locales|
        used_locales += locales
      end
      used_locales = used_locales.to_a

      # Check all used locales are defined in each localized keys
      visit_object(schema) do |key, locales|
        missing = used_locales - locales
        if missing.any?
          add_offense("#{key} missing translations for #{missing.join(', ')}", node: node)
        end
      end

      check_locales(schema["locales"], node: node)

    rescue JSON::ParserError
      # Ignored, handled in ValidSchema.
    end

    private

    def check_locales(locales, node:)
      return unless locales.is_a?(Hash)

      default_locale = locales[theme.default_locale]
      if default_locale
        locales.each_pair do |name, content|
          diff = LocaleDiff.new(default_locale, content)
          diff.add_as_offenses(self, key_prefix: ["locales", name], node: node)
        end
      else
        add_offense("Missing default locale in key: locales", node: node)
      end
    end

    def visit_object(object, top_path = [], &block)
      return unless object.is_a?(Hash)
      top_path += [object["id"]] if object["id"].is_a?(String)

      object.each_pair do |key, value|
        path = top_path + [key]

        case value
        when Array
          value.each do |item|
            visit_object(item, path, &block)
          end

        when Hash
          # Localized key
          if value[theme.default_locale].is_a?(String)
            block.call(path.join("."), value.keys)
          # Nested keys
          else
            visit_object(value, path, &block)
          end

        end
      end
    end
  end
end
