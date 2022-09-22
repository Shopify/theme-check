# frozen_string_literal: true
require "test_helper"
require "shop_context_stub"

class MetafieldAnalysisTest < Minitest::Test
  # def test_valid
  #   offenses = analyze_theme(
  #     ThemeCheck::MetafieldAnalysis.new,
  #     "templates/index.liquid" => <<~END,
  #       {% for team_member in product.metafields.custom.created_by.value %}
  #         {% for project in team_member.projects.value %}
  #           {{ project.title }}
  #         {% endfor %}
  #       {% endfor %}
  #     END
  #   )
  #   assert_offenses("", offenses)
  # end

  def test_content_reference
    check = ThemeCheck::TemplateAnalysis.new(
      ThemeCheck::ShopifyLiquid::TemplateSchemas::Collection,
      ShopContextStub
    )
    analyze_theme(
      check,
      "templates/collection.liquid" => <<~END,
          {% for product in collection.products %}
            {% for team_member in product.metafields.custom.created_by.value %}
              {% for project in team_member.projects.value %}
                {{ project.title }}
              {% endfor %}
            {% endfor %}
          {% endfor %}
      END
    )

  end


end
