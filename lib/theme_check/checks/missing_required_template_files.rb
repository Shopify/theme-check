# frozen_string_literal: true

module ThemeCheck
  # Reports missing shopify required theme files
  # required templates: https://shopify.dev/tutorials/review-theme-store-requirements-files
  class MissingRequiredTemplateFiles < LiquidCheck
    severity :error
    category :liquid
    doc docs_url(__FILE__)

    REQUIRED_LIQUID_FILES = %w(
      layout home product/Default category/Default page/Default searchresults contactpage
      error checkout/cart checkout/checkout checkout/revieworder checkout/success
      customer/account customer/address customer/details customer/login customer/reset_password
    ).map { |file| "templates/#{file}" }

    def on_end
      (REQUIRED_LIQUID_FILES - theme.liquid.map(&:name)).each do |file|
        add_offense("'#{file}.liquid' is missing") do |corrector|
          corrector.create_file(@theme.storage, "#{file}.liquid", "")
        end
      end
    end
  end
end
