# frozen_string_literal: true
require "test_helper"

module ThemeCheck
  module LanguageServer
    class DocumentLinkEngineTest < Minitest::Test
      include PositionHelper

      def test_makes_links_out_of_render_tags
        content = <<~LIQUID
          {% render '1' %}
          {%- render "2" -%}
          {% liquid
            assign x = "x"
            render '3'
          %}
          {%- liquid
            assign x = "x"
            render "4"
          -%}
        LIQUID

        engine = make_engine(
          "templates/product.liquid" => content,
        )

        assert_links_include("1", content, engine.document_links("templates/product.liquid"))
        assert_links_include("2", content, engine.document_links("templates/product.liquid"))
        assert_links_include("3", content, engine.document_links("templates/product.liquid"))
        assert_links_include("4", content, engine.document_links("templates/product.liquid"))
      end

      def assert_links_include(needle, content, links)
        target = "file:///tmp/snippets/#{needle}.liquid"
        match = links.find { |x| x[:target] == target }

        refute_nil(match, "Should find a document_link with target == '#{target}'")

        assert_equal(
          from_index_to_row_column(content, content.index(needle)),
          [
            match.dig(:range, :start, :line),
            match.dig(:range, :start, :character),
          ],
        )

        assert_equal(
          from_index_to_row_column(content, content.index(needle) + 1),
          [
            match.dig(:range, :end, :line),
            match.dig(:range, :end, :character),
          ],
        )
      end

      private

      def make_engine(files)
        storage = InMemoryStorage.new(files, "/tmp")
        DocumentLinkEngine.new(storage)
      end
    end
  end
end
