# frozen_string_literal: true
require "nokogiri"
require "forwardable"

module ThemeCheck
  class HtmlVisitor
    attr_reader :checks

    def initialize(checks)
      @checks = checks
    end

    def visit_liquid_file(liquid_file)
      visit(HtmlNode.parse(liquid_file))
    rescue ArgumentError => e
      call_checks(:on_parse_error, e, liquid_file)
    end

    private

    def visit(node)
      call_checks(:on_element, node) if node.element?
      call_checks(:"on_#{node.name}", node)
      node.children.each { |child| visit(child) }
      unless node.literal?
        call_checks(:"after_#{node.name}", node)
        call_checks(:after_element, node) if node.element?
      end
    end

    def call_checks(method, *args)
      checks.call(method, *args)
    end
  end
end
