# frozen_string_literal: true
module ThemeCheck
  class Visitor
    DISABLE_START = 'theme-check-disable'
    DISABLE_END = 'theme-check-enable'

    def initialize(checks)
      @checks = checks
      @ignoring = false
    end

    def visit_template(template)
      visit(Node.new(template.root, nil, template))
    rescue Liquid::Error => exception
      exception.template_name = template.name
      call_checks(:on_error, exception)
    end

    def visit(node)
      call_checks(:on_node, node)
      call_checks(:on_tag, node) if node.tag?
      call_checks(:"on_#{node.type_name}", node)
      node.children.each { |child| visit(child) }
      unless node.literal?
        call_checks(:"after_#{node.type_name}", node)
        call_checks(:after_tag, node) if node.tag?
        call_checks(:after_node, node)
      end

      start_ignoring if start_ignoring_comment?(node)
      stop_ignoring if stop_ignoring_comment?(node)
    end

    private

    def visit_children(node)
      node.children.each { |child| visit(child) }
    end

    def call_checks(method, *args)
      return if @ignoring

      @checks.call(method, *args)
    end

    def start_ignoring
      @ignoring = true
    end

    def stop_ignoring
      @ignoring = false
    end

    def start_ignoring_comment?(node)
      node.comment? && node.value.nodelist.join.starts_with?(DISABLE_START)
    end

    def stop_ignoring_comment?(node)
      node.comment? && node.value.nodelist.join.starts_with?(DISABLE_END)
    end
  end
end
