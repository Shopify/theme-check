# frozen_string_literal: true
require "test_helper"

class UndefinedObjectTest < Minitest::Test
  def test_report_on_undefined_object
    offenses = analyze_theme(
      ThemeCheck::UndefinedObject.new,
      "templates/index.liquid" => <<~END,
        {{ produt.title }}
      END
    )
    assert_offenses(<<~END, offenses)
      Undefined object `produt` at templates/index.liquid:1
    END
  end

  def test_report_on_undefined_object_argument
    offenses = analyze_theme(
      ThemeCheck::UndefinedObject.new,
      "templates/index.liquid" => <<~END,
        {{ form[email] }}
      END
    )
    assert_offenses(<<~END, offenses)
      Undefined object `email` at templates/index.liquid:1
    END
  end

  def test_does_not_report_on_string_argument
    offenses = analyze_theme(
      ThemeCheck::UndefinedObject.new,
      "templates/index.liquid" => <<~END,
        {{ form["email"] }}
      END
    )
    assert_offenses("", offenses)
  end

  def test_does_not_report_on_defined_object_argument
    offenses = analyze_theme(
      ThemeCheck::UndefinedObject.new,
      "templates/index.liquid" => <<~END,
        {% assign field = "email" %}
        {{ form[field] }}
      END
    )
    assert_offenses("", offenses)
  end

  def test_does_not_report_on_defined_object
    offenses = analyze_theme(
      ThemeCheck::UndefinedObject.new,
      "templates/index.liquid" => <<~END,
        {{ product.title }}
      END
    )
    assert_offenses("", offenses)
  end

  def test_does_not_report_on_assign
    offenses = analyze_theme(
      ThemeCheck::UndefinedObject.new,
      "templates/index.liquid" => <<~END,
        {% assign foo = "bar" %}
        {{ foo }}
      END
    )
    assert_offenses("", offenses)
  end

  def test_does_not_report_on_capture
    offenses = analyze_theme(
      ThemeCheck::UndefinedObject.new,
      "templates/index.liquid" => <<~END,
        {% capture 'var' %}test string{% endcapture %}
        {{ var }}
      END
    )
    assert_offenses("", offenses)
  end

  def test_does_not_report_on_forloops
    offenses = analyze_theme(
      ThemeCheck::UndefinedObject.new,
      "templates/index.liquid" => <<~END,
        {% for item in collection %}
          {{ forloop.index }}: {{ item.name }}
        {% endfor %}
      END
    )
    assert_offenses("", offenses)
  end

  def test_does_not_report_on_render
    offenses = analyze_theme(
      ThemeCheck::UndefinedObject.new,
      "templates/index.liquid" => <<~END,
        {% assign price_class = "price--large" %}
        {% render 'price', price_class: price_class %}
      END
      "snippets/price.liquid" => <<~END,
        {%- if price_class %}
          {{ price_class }}
        {% endif -%}
      END
    )
    assert_offenses("", offenses)
  end

  def test_does_not_report_on_include
    offenses = analyze_theme(
      ThemeCheck::UndefinedObject.new,
      "templates/index.liquid" => <<~END,
        {% assign price_class = "price--large" %}
        {% include 'price' %}
      END
      "snippets/price.liquid" => <<~END,
        {%- if price_class %}
          {{ price_class }}
        {% endif -%}
      END
    )
    assert_offenses("", offenses)
  end

  def test_does_not_report_on_foster_snippet
    offenses = analyze_theme(
      ThemeCheck::UndefinedObject.new,
      "snippets/price.liquid" => <<~END,
        {%- if price_class %}
          {{ price_class }}
        {% endif -%}
      END
    )
    assert_offenses("", offenses)
  end

  def test_does_not_report_on_email_in_customers_reset_password
    offenses = analyze_theme(
      ThemeCheck::UndefinedObject.new,
      "templates/customers/reset_password.liquid" => <<~END,
        <p>{{ 'customer.reset_password.subtext' | t: email: email }}</p>
      END
    )
    assert_offenses("", offenses)
  end

  def test_reportss_on_email_other_than_customers_reset_password
    offenses = analyze_theme(
      ThemeCheck::UndefinedObject.new,
      "templates/index.liquid" => <<~END,
        <p>{{ 'customer.reset_password.subtext' | t: email: email }}</p>
      END
    )
    assert_offenses(<<~END, offenses)
      Undefined object `email` at templates/index.liquid:1
    END
  end
end
