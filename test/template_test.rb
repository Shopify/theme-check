# frozen_string_literal: true
require "test_helper"

class LiquidTemplateTest < Minitest::Test
  def setup
    @template = ThemeCheck::LiquidFile.new(
      "templates/index.liquid",
      make_storage("templates/index.liquid" => <<~LIQUID)
        <h1>Title</h1>
        <p>
          {{ 1 + 2 }}
        </p>
      LIQUID
    )
  end

  def test_relative_path
    assert_equal("templates/index.liquid", @template.relative_path.to_s)
  end

  def test_type
    assert(@template.template?)
    refute(@template.snippet?)
  end

  def test_name
    assert_equal("templates/index", @template.name)
  end

  def test_excerpt
    assert_equal("{{ 1 + 2 }}", @template.source_excerpt(3))
  end
end
