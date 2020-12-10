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

    def add_as_offenses(check, key_prefix: [], node: nil, template: nil)
      if extra_keys.any?
        add_keys_offense(check, "Extra translation keys", extra_keys,
          key_prefix: key_prefix, node: node, template: template)
      end

      if missing_keys.any?
        add_keys_offense(check, "Missing translation keys", missing_keys,
          key_prefix: key_prefix, node: node, template: template)
      end
    end

    private

    def add_keys_offense(check, cause, keys, key_prefix:, node: nil, template: nil)
      message = "#{cause}: #{format_keys(key_prefix, keys)}"
      if node
        check.add_offense(message, node: node)
      else
        check.add_offense(message, template: template)
      end
    end

    def format_keys(key_prefix, keys)
      keys.map { |path| (key_prefix + path).join(".") }.join(", ")
    end

    def visit_object(default, other, path)
      default = {} unless default.is_a?(Hash)
      other = {} unless other.is_a?(Hash)
      return if pluralization?(default) && pluralization?(other)

      @extra_keys += (other.keys - default.keys).map { |key| path + [key] }

      default.each do |key, default_value|
        translated_value = other[key]
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
  end
end
