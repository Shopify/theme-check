# frozen_string_literal: true
module ThemeCheck
  # Ensure {% ... %} & {{ ... }} have consistent spaces.
  class SpaceInsideBraces < LiquidCheck
    severity :style
    category :liquid
    doc docs_url(__FILE__)

    def initialize
      @ignore = false
    end

    def on_node(node)
      return unless node.markup
      return if :assign == node.type_name

      outside_of_strings(node.markup) do |chunk|
        chunk.scan(/([,:|]|==|<>|<=|>=|<|>|!=)  +/) do |_match|
          add_offense("Too many spaces after '#{Regexp.last_match(1)}'", node: node, markup: Regexp.last_match(0))
        end
        chunk.scan(/([,:|]|==|<>|<=|>=|<\b|>\b|!=)(\S|\z)/) do |_match|
          add_offense("Space missing after '#{Regexp.last_match(1)}'", node: node, markup: Regexp.last_match(0))
        end
        chunk.scan(/  (\||==|<>|<=|>=|<|>|!=)+/) do |_match|
          add_offense("Too many spaces before '#{Regexp.last_match(1)}'", node: node, markup: Regexp.last_match(0))
        end
        chunk.scan(/(\A|\S)(?<match>\||==|<>|<=|>=|<|\b>|!=)/) do |_match|
          add_offense("Space missing before '#{Regexp.last_match(1)}'", node: node, markup: Regexp.last_match(0))
        end
      end
    end

    def on_tag(node)
      if node.inside_liquid_tag?
        markup = if node.whitespace_trimmed?
          "-%}"
        else
          "%}"
        end
        if node.markup[-1] != " " && node.markup[-1] != "\n"
          add_offense("Space missing before '#{markup}'", node: node, markup: node.markup[-1] + markup)
        elsif node.markup =~ /(\n?)(  +)\z/m && Regexp.last_match(1) != "\n"
          add_offense("Too many spaces before '#{markup}'", node: node, markup: Regexp.last_match(2) + markup)
        end
      end
      @ignore = true
    end

    def after_tag(_node)
      @ignore = false
    end

    def on_variable(node)
      return if @ignore || node.markup.empty?
      if node.markup[0] != " "
        add_offense("Space missing after '{{'", node: node) do |corrector|
          corrector.insert_before(node, " ")
        end
      end
      if node.markup[-1] != " "
        add_offense("Space missing before '}}'", node: node) do |corrector|
          corrector.insert_after(node, " ")
        end
      end
      if node.markup[0] == " " && node.markup[1] == " "
        add_offense("Too many spaces after '{{'", node: node) do |corrector|
          corrector.replace(node, " #{node.markup.lstrip}")
        end
      end
      if node.markup[-1] == " " && node.markup[-2] == " "
        add_offense("Too many spaces before '}}'", node: node) do |corrector|
          corrector.replace(node, "#{node.markup.rstrip} ")
        end
      end
    end
  end
end
