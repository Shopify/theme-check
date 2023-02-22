# frozen_string_literal: true
require "test_helper"
class VariableNameTest < Minitest::Test
  def test_assign_to_camel_case_variable
    offenses = analyze_theme(
      ThemeCheck::VariableName.new,
      "templates/index.liquid" => <<~END,
        {% assign camelCase = 1 %}
      END
    )
    assert_offenses(<<~END, offenses)
      Use snake_case for variable names at templates/index.liquid:1
    END
  end

  def test_using_camel_case_variable
    offenses = analyze_theme(
      ThemeCheck::VariableName.new,
      "templates/index.liquid" => <<~END,
        {{ camelCase }}
      END
    )
    assert_offenses(<<~END, offenses)
      Use snake_case for variable names at templates/index.liquid:1
    END
  end

  def test_using_camel_case_variable_with_filters
    offenses = analyze_theme(
      ThemeCheck::VariableName.new,
      "templates/index.liquid" => <<~END,
        {{ camelCase | t: b }}
      END
    )
    assert_offenses(<<~END, offenses)
      Use snake_case for variable names at templates/index.liquid:1
    END
  end

  def test_using_camel_case_on_object_property
    offenses = analyze_theme(
      ThemeCheck::VariableName.new,
      "templates/index.liquid" => <<~END,
        {{ shop.myTheme }}
      END
    )
    assert_offenses(<<~END, offenses)
      Use snake_case for variable names at templates/index.liquid:1
    END
  end

  def test_using_brackets
    offenses = analyze_theme(
      ThemeCheck::VariableName.new,
      "templates/index.liquid" => <<~END,
        {{ [myShop] }}
      END
    )
    assert_offenses(<<~END, offenses)
      Use snake_case for variable names at templates/index.liquid:1
    END
  end

  def test_non_variables
    offenses = analyze_theme(
      ThemeCheck::VariableName.new,
      "templates/index.liquid" => <<~END,
        {{ 'camelCase' }}
        {{ 'camelCase' | t: b }}
      END
    )
    assert_offenses("", offenses)
  end

  def test_snake_case_usage
    offenses = analyze_theme(
      ThemeCheck::VariableName.new,
      "templates/index.liquid" => <<~END,
        {{ assign snake_case = true }}
        {{ snake_case }}
        {{ snake_case | t: b }}
        {{ my_shop.my_theme }}
        {{ [some_var] }}
      END
    )
    assert_offenses("", offenses)
  end
end
