# frozen_string_literal: true
require "test_helper"

class JsonFileTest < Minitest::Test
  def setup
    @json = make_json_file("locales/en.json", "{}")
  end

  def test_name
    assert_equal("locales/en", @json.name)
  end

  def test_relative_path
    assert_equal("locales/en.json", @json.relative_path.to_s)
  end

  def test_content
    assert_equal({}, @json.content)
  end

  def test_content_with_error
    @json = make_json_file("locales/en.json", "{")
    assert_nil(@json.content)
  end

  def test_parse_error
    assert_nil(@json.parse_error)
  end

  def test_parse_error_with_error
    @json = make_json_file("locales/en.json", "{")
    assert_instance_of(JSON::ParserError, @json.parse_error)
  end

  private

  def make_json_file(name, content)
    storage = make_storage(name => content)
    ThemeCheck::JsonFile.new(name, storage)
  end
end
