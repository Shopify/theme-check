# frozen_string_literal: true

module ThemeCheck
  class MatchingTranslations < JsonCheck
    severity :suggestion

    def initialize
      @files = []
    end

    def on_file(file)
      return unless file.name.starts_with?("locales/")
      return unless file.content.is_a?(Hash)
      return if file.name == @theme.default_locale_json&.name

      @files << file
    end

    def on_end
      return unless @theme.default_locale_json&.content

      @files.each do |file|
        result = AnalyzeLocale.new(@theme.default_locale_json, file).analyze

        if result.extra_keys.any?
          add_keys_offense("Extra translation keys", result.extra_keys, result.file)
        end

        if result.missing_keys.any?
          add_keys_offense("Missing translation keys", result.missing_keys, result.file)
        end
      end
    end

    private

    def add_keys_offense(cause, keys, file)
      add_offense("#{cause}: #{format_keys(keys)}", template: file)
    end

    def format_keys(keys)
      keys.map { |path| path.join(".") }.join(", ")
    end

    class AnalyzeLocale
      AnalyzeResult = Struct.new(:extra_keys, :missing_keys, :file)
      PLURALIZATION_KEYS = Set.new(["zero", "one", "two", "few", "many", "other"])

      def initialize(default_file, locale_file)
        @default_file = default_file
        @locale_file = locale_file
      end

      def analyze
        @extra_keys = []
        @missing_keys = []

        visit_object(@default_file.content, @locale_file.content, [])

        AnalyzeResult.new(@extra_keys, @missing_keys, @locale_file)
      end

      private

      def visit_object(default_data, locale_data, path)
        default_data = {} unless default_data.is_a?(Hash)
        locale_data = {} unless locale_data.is_a?(Hash)
        return if pluralization?(default_data) && pluralization?(locale_data)

        @extra_keys += (locale_data.keys - default_data.keys).map { |key| path + [key] }

        default_data.each do |key, default_value|
          translated_value = locale_data[key]
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
end
