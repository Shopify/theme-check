# frozen_string_literal: true
require "test_helper"

class LiquidAPITest < Minitest::Test
  def test_filter_labels
    expected_labels = ["abs", "append", "asset_img_url", "asset_url", "at_least", "at_most", "brightness_difference", "camelcase", "capitalize", "ceil", "color_brightness", "color_contrast", "color_darken", "color_desaturate", "color_difference", "color_extract", "color_lighten", "color_mix", "color_modify", "color_saturate", "color_to_hex", "color_to_hsl", "color_to_rgb", "concat", "currency_selector", "customer_login_link", "customer_logout_link", "customer_register_link", "date", "default", "default_errors", "default_pagination", "divided_by", "downcase", "escape", "external_video_tag", "external_video_url", "file_img_url", "file_url", "first", "floor", "font_face", "font_modify", "font_url", "format_address", "format_code", "global_asset_url", "handle", "handleize", "highlight", "highlight_active", "hmac_sha1", "hmac_sha256", "img_tag", "img_url", "index", "join", "json", "last", "link_to", "link_to_add_tag", "link_to_remove_tag", "link_to_tag", "link_to_type", "link_to_vendor", "lstrip", "map", "md5", "media_tag", "minus", "model_viewer_tag", "modulo", "money", "money_with_currency", "money_without_currency", "money_without_trailing_zeros", "newline_to_br", "payment_button", "payment_type_img_url", "payment_type_svg_tag", "placeholder_svg_tag", "pluralize", "plus", "prepend", "product_img_url", "remove", "remove_first", "replace", "replace_first", "reverse", "round", "rstrip", "script_tag", "sha1", "sha256", "shopify_asset_url", "size", "slice", "sort", "sort_by", "split", "strip", "strip_html", "strip_newlines", "stylesheet_tag", "t", "time_tag", "times", "translate", "truncate", "truncatewords", "uniq", "upcase", "url_encode", "url_escape", "url_for_type", "url_for_vendor", "url_param_escape", "video_tag", "weight_with_unit", "where", "within"]

    actual_labels = LiquidAPI::Filters.labels
    assert_equal(expected_labels.sort, actual_labels.sort)
  end
end
