# frozen_string_literal: true

module ThemeCheck
  # Reports missing shopify required theme files
  # required templates: https://shopify.dev/tutorials/review-theme-store-requirements-files
  class MissingRequiredTemplateFiles < LiquidCheck
    severity :error
    category :liquid
    doc docs_url(__FILE__)

    REQUIRED_LIQUID_FILES = %w(layout/theme)

    REQUIRED_LIQUID_TEMPLATE_FILES = %w(
      gift_card customers/account customers/activate_account customers/addresses
      customers/login customers/order customers/register customers/reset_password
    ).map { |file| "templates/#{file}" }

    REQUIRED_JSON_TEMPLATE_FILES = %w(
      index product collection cart blog article page list-collections search 404
      password
    ).map { |file| "templates/#{file}" }

    REQUIRED_TEMPLATE_FILES = (REQUIRED_LIQUID_TEMPLATE_FILES + REQUIRED_JSON_TEMPLATE_FILES)

    def on_end
      (REQUIRED_LIQUID_FILES - theme.liquid.map(&:name)).each do |file|
        add_offense("'#{file}.liquid' is missing") do |corrector|
          corrector.create_file(@theme.storage, "#{file}.liquid", "")
        end
      end
      (REQUIRED_TEMPLATE_FILES - (theme.liquid + theme.json).map(&:name)).each do |file|
        add_offense("'#{file}.liquid' or '#{file}.json' is missing") do |corrector|
          if REQUIRED_LIQUID_TEMPLATE_FILES.include?(file)
            corrector.create_file(@theme.storage, "#{file}.liquid", "")
          else
            corrector.create_file(@theme.storage, "#{file}.json", "")
          end
        end
      end
    end
  end
end
