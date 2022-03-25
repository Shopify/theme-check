# frozen_string_literal: true
require "test_helper"

class UndefinedObjectTest < Minitest::Test
  def test_report_on_undefined_variable
    offenses = analyze_theme(
      ThemeCheck::UndefinedObject.new(exclude_snippets: false),
      "templates/index.liquid" => <<~END,
        {{ price }}
      END
    )
    assert_offenses(<<~END, offenses)
      Undefined object `price` at templates/index.liquid:1
    END
  end

  def test_report_on_repeated_undefined_variable_on_different_lines
    offenses = analyze_theme(
      ThemeCheck::UndefinedObject.new(exclude_snippets: false),
      "templates/index.liquid" => <<~END,
        {{ price }}

        {{ price }}
      END
    )
    assert_offenses(<<~END, offenses)
      Undefined object `price` at templates/index.liquid:1
      Undefined object `price` at templates/index.liquid:3
    END
  end

  def test_report_on_undefined_global_object
    offenses = analyze_theme(
      ThemeCheck::UndefinedObject.new(exclude_snippets: false),
      "templates/index.liquid" => <<~END,
        {{ produt.title }}
      END
    )
    assert_offenses(<<~END, offenses)
      Undefined object `produt` at templates/index.liquid:1
    END
  end

  def test_report_on_undefined_global_object_argument
    offenses = analyze_theme(
      ThemeCheck::UndefinedObject.new(exclude_snippets: false),
      "templates/index.liquid" => <<~END,
        {{ form[email] }}
      END
    )
    assert_offenses(<<~END, offenses)
      Undefined object `email` at templates/index.liquid:1
    END
  end

  def test_reports_several_offenses_for_same_object
    offenses = analyze_theme(
      ThemeCheck::UndefinedObject.new(exclude_snippets: false),
      "templates/index.liquid" => <<~END,
        {% if form[email] %}
          {{ form[email] }}
          {{ form[email] }}
        {% endif %}
      END
    )
    assert_offenses(<<~END, offenses)
      Undefined object `email` at templates/index.liquid:1
      Undefined object `email` at templates/index.liquid:2
      Undefined object `email` at templates/index.liquid:3
    END
  end

  def test_does_not_report_on_string_argument_to_global_object
    offenses = analyze_theme(
      ThemeCheck::UndefinedObject.new(exclude_snippets: false),
      "templates/index.liquid" => <<~END,
        {{ form["email"] }}
      END
    )
    assert_offenses("", offenses)
  end

  def test_does_not_report_on_defined_variable
    offenses = analyze_theme(
      ThemeCheck::UndefinedObject.new(exclude_snippets: false),
      "templates/index.liquid" => <<~END,
        {% assign field = "email" %}
        {{ form[field] }}
      END
    )
    assert_offenses("", offenses)
  end

  def test_does_not_report_on_defined_global_object
    offenses = analyze_theme(
      ThemeCheck::UndefinedObject.new(exclude_snippets: false),
      "templates/index.liquid" => <<~END,
        {{ product.title }}
      END
    )
    assert_offenses("", offenses)
  end

  def test_does_not_report_on_assign
    offenses = analyze_theme(
      ThemeCheck::UndefinedObject.new(exclude_snippets: false),
      "templates/index.liquid" => <<~END,
        {% assign foo = "bar" %}
        {{ foo }}
      END
    )
    assert_offenses("", offenses)
  end

  def test_does_not_report_on_capture
    offenses = analyze_theme(
      ThemeCheck::UndefinedObject.new(exclude_snippets: false),
      "templates/index.liquid" => <<~END,
        {% capture 'var' %}test string{% endcapture %}
        {{ var }}
      END
    )
    assert_offenses("", offenses)
  end

  def test_does_not_report_on_forloops
    offenses = analyze_theme(
      ThemeCheck::UndefinedObject.new(exclude_snippets: false),
      "templates/index.liquid" => <<~END,
        {% for item in collection %}
          {{ forloop.index }}: {{ item.name }}
        {% endfor %}
      END
    )
    assert_offenses("", offenses)
  end

  def test_does_not_report_on_render_using_the_with_parameter
    offenses = analyze_theme(
      ThemeCheck::UndefinedObject.new(exclude_snippets: false),
      "templates/index.liquid" => <<~END,
        {% assign featured_product = all_products['product_handle'] %}
        {% render 'product' with featured_product as my_product %}
      END
      "snippets/product.liquid" => <<~END,
        {{ my_product.available }}
      END
    )
    assert_offenses("", offenses)
  end

  def test_does_not_report_on_render_using_the_for_parameter
    offenses = analyze_theme(
      ThemeCheck::UndefinedObject.new(exclude_snippets: false),
      "templates/index.liquid" => <<~END,
        {% assign variants = product.variants %}
        {% render 'variant' for variants as my_variant %}
      END
      "snippets/variant.liquid" => <<~END,
        {{ my_variant.price }}
      END
    )
    assert_offenses("", offenses)
  end

  def test_report_on_render_with_variable_from_parent_context
    offenses = analyze_theme(
      ThemeCheck::UndefinedObject.new(exclude_snippets: false),
      "templates/index.liquid" => <<~END,
        {% assign price = "$3.00" %}
        {% render 'product' %}
      END
      "snippets/product.liquid" => <<~END,
        {{ price }}
      END
    )
    assert_offenses(<<~END, offenses)
      Missing argument `price` at templates/index.liquid:2
    END
  end

  def test_report_on_render_with_undefined_variable_as_argument
    offenses = analyze_theme(
      ThemeCheck::UndefinedObject.new(exclude_snippets: false),
      "templates/index.liquid" => <<~END,
        {% render 'product', price: adjusted_price %}
      END
    )
    assert_offenses(<<~END, offenses)
      Undefined object `adjusted_price` at templates/index.liquid:1
    END
  end

  def test_does_not_report_on_render_with_variable_as_argument
    offenses = analyze_theme(
      ThemeCheck::UndefinedObject.new(exclude_snippets: false),
      "templates/index.liquid" => <<~END,
        {% assign adjusted_price = "$3.00" %}
        {% render 'product', price: adjusted_price %}
      END
      "snippets/product.liquid" => <<~END,
        {{ price }}
      END
    )
    assert_offenses("", offenses)
  end

  def test_does_not_report_on_render_with_argument
    offenses = analyze_theme(
      ThemeCheck::UndefinedObject.new(exclude_snippets: false),
      "templates/index.liquid" => <<~END,
        {% render 'product', price: '$3.00' %}
      END
      "snippets/product.liquid" => <<~END,
        {{ price }}
      END
    )
    assert_offenses("", offenses)
  end

  def test_report_on_render_with_undefined_argument
    offenses = analyze_theme(
      ThemeCheck::UndefinedObject.new(exclude_snippets: false),
      "templates/index.liquid" => <<~END,
        {% render 'product' %}
      END
      "snippets/product.liquid" => <<~END,
        {{ price }}
      END
    )
    assert_offenses(<<~END, offenses)
      Missing argument `price` at templates/index.liquid:1
    END
  end

  def test_report_on_render_with_repeated_undefined_attribute
    offenses = analyze_theme(
      ThemeCheck::UndefinedObject.new(exclude_snippets: false),
      "templates/index.liquid" => <<~END,
        {% render 'product' %}
      END
      "snippets/product.liquid" => <<~END,
        {{ price }}

        {{ price }}
      END
    )
    assert_offenses(<<~END, offenses)
      Missing argument `price` at templates/index.liquid:1
    END
  end

  def test_report_on_render_with_undefined_argument_in_one_of_multiple_locations
    offenses = analyze_theme(
      ThemeCheck::UndefinedObject.new(exclude_snippets: false),
      "templates/index.liquid" => <<~END,
        {% render 'product' %}
      END
      "templates/collection.liquid" => <<~END,
        {% render 'product', price: "$3.00" %}
      END
      "snippets/product.liquid" => <<~END,
        {{ price }}
      END
    )
    assert_offenses(<<~END, offenses)
      Missing argument `price` at templates/index.liquid:1
    END
  end

  def test_report_on_nested_render_with_undefined_argument
    offenses = analyze_theme(
      ThemeCheck::UndefinedObject.new(exclude_snippets: false),
      "templates/index.liquid" => <<~END,
        {% render 'collection' %}
      END
      "snippets/collection.liquid" => <<~END,
        {% render 'product' %}
      END
      "snippets/product.liquid" => <<~END,
        {{ price }}
      END
    )
    assert_offenses(<<~END, offenses)
      Missing argument `price` at snippets/collection.liquid:1
    END
  end

  def test_does_not_report_on_nested_render_with_argument
    offenses = analyze_theme(
      ThemeCheck::UndefinedObject.new(exclude_snippets: false),
      "templates/index.liquid" => <<~END,
        {% render 'collection' %}
      END
      "snippets/collection.liquid" => <<~END,
        {% render 'product', price: "$3.00" %}
      END
      "snippets/product.liquid" => <<~END,
        {{ price }}
      END
    )
    assert_offenses("", offenses)
  end

  def test_does_not_report_on_unused_snippet
    offenses = analyze_theme(
      ThemeCheck::UndefinedObject.new(exclude_snippets: false),
      "snippets/product.liquid" => <<~END,
        {{ price }}
      END
    )
    assert_offenses("", offenses)
  end

  def test_does_not_report_on_email_in_customers_reset_password
    offenses = analyze_theme(
      ThemeCheck::UndefinedObject.new(exclude_snippets: false),
      "templates/customers/reset_password.liquid" => <<~END,
        <p>{{ 'customer.reset_password.subtext' | t: email: email }}</p>
      END
    )
    assert_offenses("", offenses)
  end

  def test_reports_on_email_other_than_customers_reset_password
    offenses = analyze_theme(
      ThemeCheck::UndefinedObject.new(exclude_snippets: false),
      "templates/index.liquid" => <<~END,
        <p>{{ 'customer.reset_password.subtext' | t: email: email }}</p>
      END
    )
    assert_offenses(<<~END, offenses)
      Undefined object `email` at templates/index.liquid:1
    END
  end

  def test_does_not_report_on_shopify_plus_objects_in_checkout
    offenses = analyze_theme(
      ThemeCheck::UndefinedObject.new(exclude_snippets: false),
      "layout/checkout.liquid" => <<~END,
        <p>{{ checkout_html_classes }}</p>
      END
    )
    assert_offenses("", offenses)
  end

  def test_does_not_report_on_pipe_default
    offenses = analyze_theme(
      ThemeCheck::UndefinedObject.new(exclude_snippets: false),
      "layout/checkout.liquid" => <<~END,
        {% assign obj = param | default: '' %}
        {% echo variable | default: '' %}
        {{ class | default: '' }}
      END
    )
    assert_offenses("", offenses)
  end

  def test_reports_on_shopify_plus_objects_other_than_checkout
    offenses = analyze_theme(
      ThemeCheck::UndefinedObject.new(exclude_snippets: false),
      "templates/index.liquid" => <<~END,
        <p>{{ checkout_html_classes }}</p>
      END
    )
    assert_offenses(<<~END, offenses)
      Undefined object `checkout_html_classes` at templates/index.liquid:1
    END
  end

  def test_recursion
    offenses = analyze_theme(
      ThemeCheck::UndefinedObject.new(exclude_snippets: false),
      "templates/index.liquid" => <<~END,
        {% render 'one' %}
      END
      "snippets/one.liquid" => <<~END,
        {% render 'two' %}
      END
      "snippets/two.liquid" => <<~END,
        {% if some_end_condition %}
          {% render 'one' %}
        {% endif %}
      END
    )
    assert_offenses(<<~END, offenses)
      Missing argument `some_end_condition` at snippets/one.liquid:1
    END
  end

  def test_render_block
    offenses = analyze_theme(
      ThemeCheck::UndefinedObject.new(exclude_snippets: false),
      "sections/apps.liquid" => "{% render block %}"
    )
    assert_offenses("", offenses)
  end

  def test_report_on_app_liquid_drop_in_themes
    offenses = analyze_theme(
      ThemeCheck::UndefinedObject.new(exclude_snippets: false),
      "blocks/block_a.liquid" => <<~END,
        <p>{{ app.metafields.namespace.key }}</p>
      END
    )
    assert_offenses(<<~END, offenses)
      Undefined object `app` at blocks/block_a.liquid:1
    END
  end

  def test_does_not_report_on_app_liquid_drop_in_theme_app_extensions
    offenses = analyze_theme(
      ThemeCheck::UndefinedObject.new(exclude_snippets: false, config_type: :theme_app_extension),
      "blocks/block_a.liquid" => <<~END,
        <p>{{ app.metafields.namespace.key }}</p>
      END
      "snippets/snippet_a.liquid" => <<~END,
        <p>{{ app.metafields.namespace.key }}</p>
      END
    )
    assert_offenses("", offenses)
  end
end
