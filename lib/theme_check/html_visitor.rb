# frozen_string_literal: true
require "nokogiri"
require "forwardable"

module ThemeCheck
  class HtmlVisitor
    include RegexHelpers
    attr_reader :checks

    def initialize(checks)
      @checks = checks
    end

    def visit_template(template)
      doc, placeholder_values = parse(template)
      visit(HtmlNode.new(doc, template, placeholder_values))
    rescue ArgumentError => e
      call_checks(:on_parse_error, e, template)
    end

    private

    def parse(template)
      placeholder_values = []
      parseable_source = +template.source.clone

      # Replace all non-empty liquid tags with ≬{i}######≬ to prevent the HTML
      # parser from freaking out. We transparently replace those placeholders in
      # HtmlNode.
      #
      # We're using base36 to prevent index bleeding on 36^3 tags.
      # `{{x}}` -> `≬#{i}≬` would properly be transformed for 46656 tags in a single file.
      # Should be enough.
      #
      # The base10 alternative would have overflowed at 1000 (`{{x}}` -> `≬1000≬`) which seemed more likely.
      #
      # Didn't go with base64 because of the `=` character that would have messed with HTML parsing.
      matches(parseable_source, LIQUID_TAG_OR_VARIABLE).each do |m|
        value = m[0]
        next unless value.size > 4 # skip empty tags/variables {%%} and {{}}
        placeholder_values.push(value)
        key = (placeholder_values.size - 1).to_s(36)
        parseable_source[m.begin(0)...m.end(0)] = "≬#{key.ljust(m.end(0) - m.begin(0) - 2, '#')}≬"
      end

      [
        Nokogiri::HTML5.fragment(parseable_source, max_tree_depth: 400, max_attributes: 400),
        placeholder_values,
      ]
    end

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
