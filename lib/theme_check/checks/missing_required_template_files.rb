# frozen_string_literal: true

module ThemeCheck
  # Reports missing shopify required theme files
  # required templates: https://shopify.dev/tutorials/review-theme-store-requirements-files

  class MissingRequiredTemplateFiles < LiquidCheck
    severity :error
    category :liquid
    doc "https://shopify.dev/docs/themes/theme-templates"

    LAYOUT_FILENAME = "layout/theme"
    REQUIRED_TEMPLATES_FILES = %w(index product collection cart blog article page list-collections search
      404 gift_card customers/account customers/activate_account customers/addresses customers/login customers/order
      customers/register customers/reset_password password)

    def initialize
      @layout_theme_file_found = false
      @template_files = REQUIRED_TEMPLATES_FILES.map{ |file| "templates/#{file}"}
    end

    def on_document(node)
      @layout_theme_file_found = true if node.template.name == LAYOUT_FILENAME
      @template_files.delete(node.template.name) if node.template.template?
    end

    def on_end
      add_missing_file_offense(LAYOUT_FILENAME) unless @layout_theme_file_found
      @template_files.each{ |template| add_missing_file_offense(template)}
    end

    private

    def add_missing_file_offense(file)
      add_offense("Theme is missing '#{file}.liquid' file")
    end
  end
end
