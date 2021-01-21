# frozen_string_literal: true
module ThemeCheck
  class Visitor
    DISABLE_START = 'theme-check-disable'
    DISABLE_END = 'theme-check-enable'

    def initialize(checks)
      @checks = checks

      # nil for no ignored checks
      # [] for every check ignored
      # ['CheckName'] for individual ignored checks
      @ignored_checks = nil
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

      updated_ignored_checks(node) if node.comment?
    end

    private

    def visit_children(node)
      node.children.each { |child| visit(child) }
    end

    def call_checks(method, *args)
      checks.call(method, *args)
    end

    def checks
      return @checks if @ignored_checks.nil?

      return Checks.new if @ignored_checks.empty?

      Checks.new(@checks.reject { |check| @ignored_checks.include?(check.code_name) })
    end

    def updated_ignored_checks(node)
      value = node.value.nodelist.join

      if value.starts_with?(DISABLE_START)
        @ignored_checks = value.gsub(DISABLE_START, '').strip.split(',').map(&:strip)
      elsif value.starts_with?(DISABLE_END)
        # Ignore everything, regardless of what was passed
        @ignored_checks = nil
      end
    end

    def start_ignoring_comment?(node)
      node.comment? && node.value.nodelist.join.starts_with?(DISABLE_START)
    end

    def stop_ignoring_comment?(node)
      node.comment? && node.value.nodelist.join.starts_with?(DISABLE_END)
    end
  end
end
