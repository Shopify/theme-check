# frozen_string_literal: true
require "test_helper"

class AssetFileTest < Minitest::Test
  def setup
    @asset = make_asset_file("assets/theme.js", "")
  end

  def test_name
    assert_equal("assets/theme.js", @asset.name)
  end

  def test_relative_path
    assert_equal("assets/theme.js", @asset.relative_path.to_s)
  end

  def test_content
    assert_equal("", @asset.content)
  end

  def test_gzipped_size
    assert_equal(20, @asset.gzipped_size)
  end

  private

  def make_asset_file(name, content)
    storage = make_storage(name => content)
    ThemeCheck::AssetFile.new(name, storage)
  end
end
