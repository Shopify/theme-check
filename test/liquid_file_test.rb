# frozen_string_literal: true
require "test_helper"

class LiquidFileTest < Minitest::Test
  def setup
    @theme_file = PlatformosCheck::LiquidFile.new(
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
    assert_equal("templates/index.liquid", @theme_file.relative_path.to_s)
  end

  def test_type
    assert(@theme_file.template?)
    refute(@theme_file.snippet?)
  end

  def test_name
    assert_equal("templates/index", @theme_file.name)
  end

  def test_excerpt
    assert_equal("{{ 1 + 2 }}", @theme_file.source_excerpt(3))
  end
end
