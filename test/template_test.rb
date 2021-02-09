# frozen_string_literal: true
require "test_helper"

class TemplateTest < Minitest::Test
  def setup
    content = <<~LIQUID
      <h1>Title</h1>
      <p>
        {{ 1 + 2 }}
      </p>
    LIQUID
    theme = make_file_system_theme("templates/index.liquid" => content)
    @templates = [
      ThemeCheck::FileSystemTemplate.new(
        theme.root.join("templates/index.liquid"),
        theme.root
      ),
      ThemeCheck::InMemoryTemplate.new(
        "templates/index.liquid",
        content
      ),
    ]
  end

  def test_relative_path
    @templates.each do |template|
      assert_equal("templates/index.liquid", template.relative_path.to_s)
    end
  end

  def test_type
    @templates.each do |template|
      assert(template.template?)
      refute(template.snippet?)
    end
  end

  def test_name
    @templates.each do |template|
      assert_equal("templates/index", template.name)
    end
  end

  def test_excerpt
    @templates.each do |template|
      assert_equal("{{ 1 + 2 }}", template.excerpt(3))
    end
  end
end
