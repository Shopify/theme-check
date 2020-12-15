# frozen_string_literal: true

module ThemeCheck
  # Reports missing shopify required theme files
  # required templates: https://shopify.dev/tutorials/review-theme-store-requirements-files

  class MissingRequiredTemplateFiles < LiquidCheck
    severity :error
    category :liquid
    doc "https://shopify.dev/docs/themes/theme-templates"

    LAYOUT_FILENAME = "layout/theme"
    REQUIRED_TEMPLATES_FILES = %w(index product collection cart blog article page list-collections search 404
                                  gift_card customers/account customers/activate_account customers/addresses
                                  customers/login customers/order customers/register customers/reset_password password)
      .map { |file| "templates/#{file}" }

    def on_end
      missing_files = (REQUIRED_TEMPLATES_FILES + [LAYOUT_FILENAME]) - theme.liquid.map(&:name)
      missing_files.each { |file| add_missing_file_offense(file) }
    end

    private

    def add_missing_file_offense(file)
      add_offense("Theme is missing '#{file}.liquid' file")
    end
  end
end
