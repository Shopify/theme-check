# frozen_string_literal: true
module ThemeCheck
  class LocaleDiff
    PLURALIZATION_KEYS = Set.new(["zero", "one", "two", "few", "many", "other"])

    attr_reader :extra_keys, :missing_keys

    def initialize(default, other)
      @default = default
      @other = other
      @extra_keys = []
      @missing_keys = []

      visit_object(@default, @other, [])
    end

    def add_as_offenses(check, key_prefix: [], node: nil, theme_file: nil, schema: {})
      if extra_keys.any?
        remove_extra_keys_offense(check, "Extra translation keys", extra_keys,
          key_prefix: key_prefix, node: node, theme_file: theme_file, schema: schema)
      end

      if missing_keys.any?
        add_missing_keys_offense(check, "Missing translation keys", missing_keys,
          key_prefix: key_prefix, node: node, theme_file: theme_file, schema: schema)
      end
    end

    private

    def remove_extra_keys_offense(check, cause, extra_keys, key_prefix:, node: nil, theme_file: nil, schema: {})
      message = "#{cause}: #{format_keys(key_prefix, extra_keys)}"
      if node
        check.add_offense(message, node: node) do |corrector|
          extra_keys.each do |k|
            SchemaHelper.delete(schema, key_prefix + k)
          end
          corrector.replace_inner_json(node, schema)
        end
      elsif theme_file.is_a?(JsonFile)
        check.add_offense(message, theme_file: theme_file) do |corrector|
          extra_keys.each do |k|
            corrector.remove_translation(theme_file, key_prefix + k)
          end
        end
      else
        check.add_offense(message, theme_file: theme_file)
      end
    end

    def add_missing_keys_offense(check, cause, missing_keys, key_prefix:, node: nil, theme_file: nil, schema: {})
      message = "#{cause}: #{format_keys(key_prefix, missing_keys)}"
      if node
        check.add_offense(message, node: node) do |corrector|
          missing_keys.each do |k|
            SchemaHelper.set(schema, key_prefix + k, "TODO")
          end
          corrector.replace_inner_json(node, schema)
        end
      elsif theme_file.is_a?(JsonFile)
        check.add_offense(message, theme_file: theme_file) do |corrector|
          missing_keys.each do |k|
            corrector.add_translation(theme_file, key_prefix + k, "TODO")
          end
        end
      else
        check.add_offense(message, theme_file: theme_file)
      end
    end

    def format_keys(key_prefix, keys)
      keys.map { |path| (key_prefix + path).join(".") }.join(", ")
    end

    def visit_object(default, other, path)
      default = {} unless default.is_a?(Hash)
      other = {} unless other.is_a?(Hash)
      return if pluralization?(default) && pluralization?(other)

      shopify_translations = system_translations(path)

      @extra_keys += (other.keys - default.keys - shopify_translations.keys).map { |key| path + [key] }

      default.each do |key, default_value|
        translated_value = other[key] || shopify_translations[key]
        new_path = path + [key]

        if translated_value.nil?
          @missing_keys << new_path
        else
          visit_object(default_value, translated_value, new_path)
        end
      end
    end

    def pluralization?(hash)
      hash.all? do |key, value|
        PLURALIZATION_KEYS.include?(key) && !value.is_a?(Hash)
      end
    end

    def system_translations(path)
      return ShopifyLiquid::SystemTranslations.translations_hash if path.empty?
      ShopifyLiquid::SystemTranslations.translations_hash.dig(*path) || {}
    end
  end
end
