# frozen_string_literal: true
module ThemeCheck
  class Visitor
    attr_reader :checks

    def initialize(checks)
      @checks = checks
    end

    def visit_template(template)
      @disabled_checks = DisabledChecks.new
      visit(Node.new(template.root, nil, template))
      remove_disabled_offenses
    rescue Liquid::Error => exception
      exception.template_name = template.name
      call_checks(:on_error, exception)
    end

    private

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

      @disabled_checks.update(node) if node.comment?
    end

    def call_checks(method, *args)
      checks.call(method, *args)
    end

    def remove_disabled_offenses
      checks.disableable.each do |check|
        check.offenses.reject! do |offense|
          @disabled_checks.disabled?(offense.code_name, offense.start_index)
        end
      end
    end
  end
end
