# frozen_string_literal: true
require "test_helper"

class LiquidAPITest < Minitest::Test
  def test_filter_labels
    expected_labels = ["date", "default", "default_errors", "default_pagination", "format_address", "highlight", "highlight_active", "json", "placeholder_svg_tag", "time_tag", "weight_with_unit", "concat", "join", "first", "index", "last", "map", "reverse", "size", "sort", "uniq", "where", "brightness_difference", "color_brightness", "color_contrast", "color_darken", "color_desaturate", "color_difference", "color_extract", "color_lighten", "color_mix", "color_modify", "color_saturate", "color_to_rgb", "color_to_hsl", "color_to_hex", "font_face", "font_modify", "font_url", "currency_selector", "img_tag", "payment_button", "payment_type_svg_tag", "script_tag", "stylesheet_tag", "external_video_tag", "external_video_url", "img_url", "media_tag", "model_viewer_tag", "video_tag", "abs", "at_least", "at_most", "ceil", "divided_by", "floor", "minus", "plus", "round", "times", "modulo", "money", "money_with_currency", "money_without_trailing_zeros", "money_without_currency", "append", "camelcase", "capitalize", "downcase", "escape", "handleize", "hmac_sha1", "hmac_sha256", "md5", "newline_to_br", "pluralize", "prepend", "remove", "remove_first", "replace", "replace_first", "slice", "split", "strip", "lstrip", "rstrip", "sha1", "sha256", "strip_html", "strip_newlines", "truncate", "truncatewords", "upcase", "url_encode", "url_escape", "url_param_escape", "asset_img_url", "asset_url", "file_img_url", "file_url", "customer_login_link", "global_asset_url", "link_to", "link_to_vendor", "link_to_type", "link_to_tag", "link_to_add_tag", "link_to_remove_tag", "payment_type_img_url", "shopify_asset_url", "sort_by", "url_for_type", "url_for_vendor", "within", "t", "translate"]

    actual_labels = LiquidAPI::Filters.labels
    assert_equal(expected_labels.sort, actual_labels.sort)
  end
end
