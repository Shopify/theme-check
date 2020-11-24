module ThemeCheck
  class Visitor
    def initialize(checks)
      @checks = checks
    end

    def visit_template(template, path: nil)
      visit(Node.new(template.root, nil, path))
    end

    def visit(node)
      call_checks(:on_tag, node) if node.tag?
      call_checks(:"on_#{node.type_name}", node)
      node.children.each { |child| visit(child) }
      unless node.literal?
        call_checks(:"after_#{node.type_name}", node)
        call_checks(:after_tag, node) if node.tag?
      end
    end

    private

    def visit_children(node)
      node.children.each { |child| visit(child) }
    end

    def call_node_checks_around(node, *types)
      types += [:node, node.type_name]
      types.each { |type| call_checks("on_#{type}", node) }
      yield
      types.each { |type| call_checks("after_#{type}", node) }
    end

    def call_checks(method, *args)
      @checks.call(method, *args)
    end
  end
end
