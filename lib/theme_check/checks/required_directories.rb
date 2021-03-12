# frozen_string_literal: true
module ThemeCheck
  # Reports missing shopify required directories

  class RequiredDirectories < LiquidCheck
    severity :error
    category :liquid
    doc docs_url(__FILE__)

    REQUIRED_DIRECTORIES = %w(assets config layout locales sections snippets templates)

    def on_end
      directories = theme.directories.map(&:to_s)
      missing_directories = REQUIRED_DIRECTORIES - directories
      missing_directories.each { |d| add_missing_directories_offense(d) }
    end

    private

    def add_missing_directories_offense(directory)
      add_offense("Theme is missing '#{directory}' directory")
    end
  end
end
