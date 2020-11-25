# frozen_string_literal: true
require "test_helper"

class TemplateTest < Minitest::Test
  def setup
    theme = make_theme("templates/index.liquid" => <<~END)
      <h1>Title</h1>
      <p>
        {{ 1 + 2 }}
      </p>
    END
    @template = ThemeCheck::Template.new(theme.root.join("templates/index.liquid"), theme.root)
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
    assert_equal("{{ 1 + 2 }}", @template.excerpt(3))
  end
end
