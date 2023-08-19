# frozen_string_literal: true
require "test_helper"

module PlatformosCheck
  class AppBlockValidTagsTest < Minitest::Test
    def test_include_layout_section_tags
      ['include', 'layout', 'section', 'sections'].each do |tag|
        extension_files = {
          "blocks/app.liquid" => <<~BLOCK,
            {% #{tag} 'test' %}
            {% schema %}
            { }
            {% endschema %}
          BLOCK
        }
        offenses = analyze_theme(
          AppBlockValidTags.new,
          extension_files,
        )
        assert_offenses("Theme app extension blocks cannot contain #{tag} tags at blocks/app.liquid:1", offenses)
      end
    end

    def test_javascript_and_stylesheet_tag
      ['javascript', 'stylesheet'].each do |tag|
        extension_files = {
          "blocks/app.liquid" => <<~BLOCK,
            {% #{tag} %}
            {% end#{tag} %}
            {% schema %}
            { }
            {% endschema %}
          BLOCK
        }
        offenses = analyze_theme(
          AppBlockValidTags.new,
          extension_files,
        )
        assert_offenses("Theme app extension blocks cannot contain #{tag} tags at blocks/app.liquid:1", offenses)
      end
    end
  end
end
