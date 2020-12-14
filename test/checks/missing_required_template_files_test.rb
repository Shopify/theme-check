# frozen_string_literal: true
require "test_helper"

class MissingRequiredTemplateFilesTest < Minitest::Test
  def test_reports_missing_layout_theme_file
    offenses = analyze_theme(
      ThemeCheck::MissingRequiredTemplateFiles.new,
      "templates/index.liquid" => "",
      "templates/product.liquid" => "",
    )

    assert_includes(offenses.sort_by(&:location).join("\n"), "Theme is missing 'layout/theme.liquid' file")
  end

  def test_reports_missing_template_files
    offenses = analyze_theme(
      ThemeCheck::MissingRequiredTemplateFiles.new,
      "layout/theme.liquid" => "",
    )

    assert_includes(offenses.sort_by(&:location).join("\n"),
      "Theme is missing 'templates/index.liquid' file")

    assert_includes(offenses.sort_by(&:location).join("\n"),
      "Theme is missing 'templates/product.liquid' file")
  end

  def test_does_not_report_missing_template_files
    offenses = analyze_theme(
      ThemeCheck::MissingRequiredTemplateFiles.new,
      "layout/theme.liquid" => "",
      "templates/index.liquid" => "",
      "templates/product.liquid" => "",
      "templates/collection.liquid" => "",
      "templates/cart.liquid" => "",
      "templates/blog.liquid" => "",
      "templates/article.liquid" => "",
      "templates/page.liquid" => "",
      "templates/list-collections.liquid" => "",
      "templates/search.liquid" => "",
      "templates/404.liquid" => "",
      "templates/gift_card.liquid" => "",
      "templates/customers/account.liquid" => "",
      "templates/customers/activate_account.liquid" => "",
      "templates/customers/addresses.liquid" => "",
      "templates/customers/login.liquid" => "",
      "templates/customers/order.liquid" => "",
      "templates/customers/register.liquid" => "",
      "templates/customers/reset_password.liquid" => "",
      "templates/password.liquid" => "",
    )

    assert_empty(offenses)
  end
end
