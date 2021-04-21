# frozen_string_literal: true
require "test_helper"

class LocaleDiffTest < Minitest::Test
  def test_no_diff
    diff = ThemeCheck::LocaleDiff.new(
      { "title" => "Hello" },
      { "title" => "Bonjour" }
    )
    assert_empty(diff.extra_keys)
    assert_empty(diff.missing_keys)
  end

  def test_extra_keys
    diff = ThemeCheck::LocaleDiff.new(
      { "title" => "Hello", "general" => {} },
      {
        "title" => "Bonjour",
        "help" => "Aide",
        "sections" => {
          "name" => "Nom",
        },
        "general" => {
          "product" => "Produit",
        },
      },
    )
    assert_equal([["help"], ["sections"], ["general", "product"]], diff.extra_keys)
    assert_empty(diff.missing_keys)
  end

  def test_missing_keys
    diff = ThemeCheck::LocaleDiff.new(
      {
        "title" => "Bonjour",
        "help" => "Aide",
        "general" => {
          "product" => "Produit",
        },
      },
      { "title" => "Hello", "general" => {} },
    )
    assert_equal([["help"], ["general", "product"]], diff.missing_keys)
    assert_empty(diff.extra_keys)
  end

  class MockCheck < ThemeCheck::LiquidCheck; end

  def test_add_as_offenses
    diff = ThemeCheck::LocaleDiff.new(
      { "help" => "Aide" },
      { "title" => "Hello" },
    )
    check = MockCheck.new
    diff.add_as_offenses(check, key_prefix: ["locales"])
    assert_offenses(<<~END, check.offenses)
      Extra translation keys: locales.title
      Missing translation keys: locales.help
    END
  end
end
