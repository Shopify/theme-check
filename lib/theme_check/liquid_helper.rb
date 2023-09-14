# frozen_string_literal: true

module ThemeCheck
  module LiquidHelper
    def recover_variable_markup(variable_lookup)
      variable_lookup.name + recover_lookups_markup(variable_lookup.lookups)
    end

    def recover_single_condition_markup(condition)
      return '' if condition.else?

      text = recover_expression_markup(condition.left)
      text += ' ' + condition.operator.to_s + ' ' + recover_expression_markup(condition.right) if condition.operator
      text
    end

    def recover_composite_condition_markup(condition)
      return '' if condition.else?

      text = recover_single_condition_markup(condition)
      return text unless condition.child_condition

      text += ' ' + condition.send(:child_relation).to_s + ' '
      text += recover_composite_condition_markup(condition.child_condition)
      text
    end

    def recover_lookups_markup(lookups)
      lookups.map do |lookup|
        next "[#{recover_variable_markup(lookup)}]" if lookup.is_a?(Liquid::VariableLookup)
        next "[#{recover_expression_markup(item.start_obj)}..#{recover_expression_markup(item.end_obj)}]" if lookup.is_a?(Liquid::RangeLookup)
        next ".#{lookup}" if lookup.is_a?(String)
        next "[#{lookup}]" if lookup.is_a?(Integer)
      end.join
    end

    def recover_expression_markup(item)
      return recover_variable_markup(item) if item.is_a?(Liquid::VariableLookup)
      return "#{recover_expression_markup(item.start_obj)}..#{recover_expression_markup(item.end_obj)}" if item.is_a?(Liquid::RangeLookup)

      item.to_s
    end

    def condition_relations(condition)
      condition.child_condition ? [condition.send(:child_relation)] + condition_relations(condition.child_condition) : []
    end

    def subconditions(condition)
      condition.child_condition ? [condition] + subconditions(condition.child_condition) : [condition]
    end

    def inverted_condition?(condition)
      !condition.left.is_a?(Liquid::VariableLookup) && condition.right.is_a?(Liquid::VariableLookup)
    end

    def standard_condition?(condition)
      condition.left.is_a?(Liquid::VariableLookup) && !condition.right.is_a?(Liquid::VariableLookup)
    end

    def plain_condition?(condition)
      condition.left.is_a?(Liquid::VariableLookup) && condition.operator.nil?
    end

    def method_literal_condition?(condition, operators)
      standard_condition?(condition) && operators.include?(condition.operator) && blank_or_empty_literal?(condition.right)
    end

    def not_blank_condition?(condition)
      # { x } or { x != blank } or { x != empty }
      plain_condition?(condition) || method_literal_condition?(condition, ['!=', '<>'])
    end

    def blank_condition?(condition)
      # { x == blank } or { x == empty }
      method_literal_condition?(condition, ['=='])
    end

    def positive_size_condition?(condition)
      # { x.size > 0 } or { x.size >= 1 } or { x != blank } or { x != empty }
      method_literal_condition?(condition, ['!=', '<>']) ||
        (standard_condition?(condition) && condition.left.lookups.last == 'size' && condition.operator == '>' && condition.right == 0) ||
        (standard_condition?(condition) && condition.left.lookups.last == 'size' && condition.operator == '>=' && condition.right == 1)
    end

    def zero_size_condition?(condition)
      # { x.size == 0 } or { x == blank } or { x == empty }
      method_literal_condition?(condition, ['!=', '<>']) ||
        (standard_condition?(condition) && condition.left.lookups.last == 'size' && condition.operator == '==' && condition.right == 0)
    end

    def blank_or_empty_literal?(literal)
      literal.is_a?(Liquid::Condition::MethodLiteral) && %w[blank empty].include?(literal.to_s)
    end

    def strippable_from_nodelist?(value)
      value.is_a?(String) && (value.empty? || value.strip.empty? && value.include?("\n"))
    end

    def stripped_nodelist(nodelist)
      nodelist = nodelist.dup
      nodelist.shift if strippable_from_nodelist?(nodelist.first)
      nodelist.pop if strippable_from_nodelist?(nodelist.last)
      nodelist
    end

    def no_liquid?(html)
      ThemeCheck.with_liquid_c_disabled do
        Liquid::Template.parse(html).root.nodelist.all?(String)
      rescue Liquid::SyntaxError
        false
      end
    end
  end
end
