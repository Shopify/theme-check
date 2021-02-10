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
    files = {
      "templates/index.liquid" => content,
    }
    file_system_storage = make_file_system_storage(files)
    in_memory_storage = make_in_memory_storage(files)
    @templates = [
      ThemeCheck::Template.new(
        "templates/index.liquid",
        file_system_storage
      ),
      ThemeCheck::Template.new(
        "templates/index.liquid",
        in_memory_storage
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
