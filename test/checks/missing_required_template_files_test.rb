# frozen_string_literal: true
require "test_helper"

class MissingRequiredTemplateFilesTest < Minitest::Test
  def test_reports_missing_layout_theme_file
    offenses = analyze_theme(
      PlatformosCheck::MissingRequiredTemplateFiles.new,
      "templates/index.liquid" => "",
      "templates/product.liquid" => "",
    )

    assert_includes_offense(offenses, "'layout/theme.liquid' is missing")
  end

  def test_reports_missing_template_files
    offenses = analyze_theme(
      PlatformosCheck::MissingRequiredTemplateFiles.new,
      "layout/theme.liquid" => "",
    )

    assert_includes_offense(offenses, "'templates/index.liquid' or 'templates/index.json' is missing")
    assert_includes_offense(offenses, "'templates/product.liquid' or 'templates/product.json' is missing")
  end

  def test_does_not_report_missing_template_files
    offenses = analyze_theme(
      PlatformosCheck::MissingRequiredTemplateFiles.new,
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

  def test_does_not_report_missing_template_files_with_json_templates
    offenses = analyze_theme(
      PlatformosCheck::MissingRequiredTemplateFiles.new,
      "layout/theme.liquid" => "",
      "templates/index.json" => "",
      "templates/product.json" => "",
      "templates/collection.json" => "",
      "templates/cart.json" => "",
      "templates/blog.json" => "",
      "templates/article.json" => "",
      "templates/page.json" => "",
      "templates/list-collections.json" => "",
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

    assert_offenses("", offenses)
  end

  def test_creates_missing_layout_theme_file
    theme = make_theme(
      "templates/index.liquid" => "",
      "templates/product.liquid" => "",
    )

    analyzer = PlatformosCheck::Analyzer.new(theme, [PlatformosCheck::MissingRequiredTemplateFiles.new], true)
    analyzer.analyze_theme
    analyzer.correct_offenses

    assert(theme.storage.files.include?("layout/theme.liquid"))
  end

  def test_creates_missing_template_files
    theme = make_theme(
      "layout/theme.liquid" => "",
      "templates/index.json" => "",
      "templates/collection.json" => "",
      "templates/cart.json" => "",
      "templates/blog.json" => "",
      "templates/article.json" => "",
      "templates/page.json" => "",
      "templates/list-collections.json" => "",
      "templates/404.json" => "",
      "templates/customers/account.liquid" => "",
      "templates/customers/activate_account.liquid" => "",
      "templates/customers/addresses.liquid" => "",
      "templates/customers/order.liquid" => "",
      "templates/customers/register.liquid" => "",
      "templates/customers/reset_password.liquid" => "",
    )

    missing_files = ["templates/product.json", "templates/search.json", "templates/customers/login.liquid", "templates/password.json", "templates/gift_card.liquid"]

    analyzer = PlatformosCheck::Analyzer.new(theme, [PlatformosCheck::MissingRequiredTemplateFiles.new], true)
    analyzer.analyze_theme
    analyzer.correct_offenses

    assert(missing_files.all? { |file| theme.storage.files.include?(file) })
  end
end
