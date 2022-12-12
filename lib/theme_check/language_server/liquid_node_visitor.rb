# frozen_string_literal: true

module ThemeCheck
  module LanguageServer
    class LiquidNodeVisitor
      def initialize(handlers)
        @handlers = handlers
      end

      def visit_liquid_file(liquid_file)
        return unless liquid_file

        visit(liquid_node(liquid_file))
      rescue Liquid::Error => exception
        # dont care
      end

      private

      def visit(node)
        return if node.type_name == :variable_lookup

        method = :"on_#{node.type_name}"
        # for each handler, call the method if it has an implemnation
        @handlers.each do |handler|
          handler.send(method, node) if handler.respond_to?(method)
        end

        node.children.each { |child| visit(child) }
      end

      def liquid_node(liquid_file)
        LiquidNode.new(liquid_file.root, nil, liquid_file)
      end
    end
  end
end
