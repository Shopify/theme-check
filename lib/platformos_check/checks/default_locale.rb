# frozen_string_literal: true
module PlatformosCheck
  class DefaultLocale < JsonCheck
    severity :suggestion
    category :translation
    doc docs_url(__FILE__)

    def on_end
      return if @theme.default_locale_json
      add_offense("Default translation file not found (for example locales/en.default.json)") do |corrector|
        corrector.create_file(@theme.storage, "locales/#{theme.default_locale}.default.json", "{}")
      end
    end
  end
end
