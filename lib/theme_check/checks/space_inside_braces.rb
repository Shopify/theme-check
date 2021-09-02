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

      outside_of_strings(node.markup) do |chunk, chunk_start|
        chunk.scan(/([,:|]|==|<>|<=|>=|<|>|!=)(  +)/) do |_match|
          add_offense(
            "Too many spaces after '#{Regexp.last_match(1)}'",
            node: node,
            markup: Regexp.last_match(2),
            node_markup_offset: chunk_start + Regexp.last_match.begin(2)
          )
        end
        chunk.scan(/([,:|]|==|<>|<=|>=|<\b|>\b|!=)(\S|\z)/) do |_match|
          add_offense(
            "Space missing after '#{Regexp.last_match(1)}'",
            node: node,
            markup: Regexp.last_match(1),
            node_markup_offset: chunk_start + Regexp.last_match.begin(0),
          )
        end
        chunk.scan(/(  +)(\||==|<>|<=|>=|<|>|!=)+/) do |_match|
          add_offense(
            "Too many spaces before '#{Regexp.last_match(2)}'",
            node: node,
            markup: Regexp.last_match(1),
            node_markup_offset: chunk_start + Regexp.last_match.begin(1)
          )
        end
        chunk.scan(/(\A|\S)(?<match>\||==|<>|<=|>=|<|\b>|!=)/) do |_match|
          add_offense(
            "Space missing before '#{Regexp.last_match(1)}'",
            node: node,
            markup: Regexp.last_match(:match),
            node_markup_offset: chunk_start + Regexp.last_match.begin(:match)
          )
        end
      end
    end

    def on_tag(node)
      unless node.inside_liquid_tag?
        if node.markup[-1] != " " && node.markup[-1] != "\n"
          add_offense(
            "Space missing before '#{node.end_token}'",
            node: node,
            markup: node.markup[-1],
            node_markup_offset: node.markup.size - 1,
          )
        elsif node.markup =~ /(\n?)(  +)\z/m && Regexp.last_match(1) != "\n"
          add_offense(
            "Too many spaces before '#{node.end_token}'",
            node: node,
            markup: Regexp.last_match(2),
            node_markup_offset: node.markup.size - Regexp.last_match(2).size
          )
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
        add_offense(
          "Space missing after '#{node.start_token}'",
          node: node,
          markup: node.markup[0]
        ) do |corrector|
          corrector.insert_before(node, " ")
        end
      end
      if node.markup[-1] != " " && node.markup[-1] != "\n"
        add_offense(
          "Space missing before '#{node.end_token}'",
          node: node,
          markup: node.markup[-1],
          node_markup_offset: node.markup.size - 1,
        ) do |corrector|
          corrector.insert_after(node, " ")
        end
      end
      if node.markup =~ /\A(  +)/m
        add_offense(
          "Too many spaces after '#{node.start_token}'",
          node: node,
          markup: Regexp.last_match(1),
        ) do |corrector|
          corrector.replace(node, " #{node.markup.lstrip}")
        end
      end
      if node.markup =~ /(\n?)(  +)\z/m && Regexp.last_match(1) != "\n"
        add_offense(
          "Too many spaces before '#{node.end_token}'",
          node: node,
          markup: Regexp.last_match(2),
          node_markup_offset: node.markup.size - Regexp.last_match(2).size
        ) do |corrector|
          corrector.replace(node, "#{node.markup.rstrip} ")
        end
      end
    end
  end
end
