# frozen_string_literal: true
module ThemeCheck
  # Checks unused {% assign x = ... %} or {% capture x %}...{% endcapture %} tags
  class UnusedAssign < LiquidCheck
    severity :suggestion
    category :liquid
    doc docs_url(__FILE__)

    def initialize
      @unused = {}
    end

    def on_document(node)
      @unused.clear
      @used_include_tag = false
    end

    def on_assign(node)
      declare(node, node.value.to)
    end

    def on_capture(node)
      declare(node, node.value.instance_variable_get('@to'))
    end

    def on_variable_lookup(node)
      @unused.delete(node.value.name)
    end

    def on_include(node)
      @used_include_tag = true
    end

    def after_document(node)
      return if @used_include_tag

      @unused.each do |name, nodes|
        nodes.each do |node|
          case node.value
          when Liquid::Assign
            add_offense("Unused assign `#{name}`", node: node)
          when Liquid::Capture
            add_offense("Unused capture `#{name}`", node: node)
          end
        end
      end
    end

    private

    def declare(node, name)
      @unused[name] ||= []
      @unused[name].push(node)
    end
  end
end
