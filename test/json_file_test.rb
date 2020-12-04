# frozen_string_literal: true
require "test_helper"

class JsonFileTest < Minitest::Test
  def test_name
    json = make_json_file("locales/en.json", "{}")
    assert_equal("locales/en", json.name)
  end

  def test_relative_path
    json = make_json_file("locales/en.json", "{}")
    assert_equal("locales/en.json", json.relative_path.to_s)
  end

  def test_content
    json = make_json_file("locales/en.json", "{}")
    assert_equal({}, json.content)
  end

  def test_content_with_error
    json = make_json_file("locales/en.json", "{")
    assert_nil(json.content)
  end

  def test_parse_error
    json = make_json_file("locales/en.json", "{}")
    assert_nil(json.parse_error)
  end

  def test_parse_error_with_error
    json = make_json_file("locales/en.json", "{")
    assert_instance_of(JSON::ParserError, json.parse_error)
  end

  private

  def make_json_file(name, content)
    theme = make_theme(name => content)
    ThemeCheck::JsonFile.new(theme.root.join(name), theme.root)
  end
end
