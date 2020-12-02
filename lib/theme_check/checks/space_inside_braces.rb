# frozen_string_literal: true
module ThemeCheck
  # Ensure {% ... %} & {{ ... }} have consistent spaces.
  class SpaceInsideBraces < Check
    severity :style

    def initialize
      @ignore = false
    end

    def on_node(node)
      return unless node.markup

      outside_of_strings(node.markup) do |chunk|
        chunk.scan(/([,:])  +/) do |_match|
          add_offense("Too many spaces after '#{Regexp.last_match(1)}'", node: node, markup: Regexp.last_match(0))
        end
        chunk.scan(/([,:])\S/) do |_match|
          add_offense("Space missing after '#{Regexp.last_match(1)}'", node: node, markup: Regexp.last_match(0))
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
          add_offense("Space missing at the end of {% ... %}", node: node, markup: node.markup[-1] + markup)
        elsif node.markup =~ /(\n?)(  +)\z/m && Regexp.last_match(1) != "\n"
          add_offense("Too many spaces at the end of {% ... %}", node: node, markup: Regexp.last_match(2) + markup)
        end
      end
      @ignore = true
    end

    def after_tag(_node)
      @ignore = false
    end

    def on_variable(node)
      return if @ignore
      if node.markup[0] != " "
        add_offense("Space missing at the start of {{ ... }}", node: node)
      elsif node.markup[-1] != " "
        add_offense("Space missing at the end of {{ ... }}", node: node)
      elsif node.markup[1] == " "
        add_offense("Too many spaces at the start of {{ ... }}", node: node)
      elsif node.markup[-2] == " "
        add_offense("Too many spaces at the end of {{ ... }}", node: node)
      end
    end
  end
end
