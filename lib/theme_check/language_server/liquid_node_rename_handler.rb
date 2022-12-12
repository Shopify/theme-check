# frozen_string_literal: true

module ThemeCheck
  module LanguageServer
    class LiquidNodeRenameHandler
      attr_reader :render_nodes, :include_nodes

      def initialize
        @render_nodes = []
        @include_nodes = []
      end

      def on_render(node)
        binding.pry
        @render_nodes << node
      end

      def on_include(node)
        @include_nodes << node
      end
    end
  end
end