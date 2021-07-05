# frozen_string_literal: true

module ThemeCheck
  class DefaultLocale < JsonCheck
    severity :suggestion
    category :translation
    doc docs_url(__FILE__)

    def on_end
      return if @theme.default_locale_json
      add_offense("Default translation file not found (for example locales/en.default.json)")
      #create the file
      if JsonFile.new('locales/en.default.json', FileSystemStorage.new('locales/en.default.json'))
        add_offense("File created")
      end
    end
  end
end
