# frozen_string_literal: true
require "test_helper"

module PlatformosCheck
  module LanguageServer
    class CompletionEngineTest < Minitest::Test
      def setup
        super
        skip("Liquid-C not supported") if liquid_c_enabled?
      end

      def test_complete_tag
        engine = make_engine(filename => <<~LIQUID)
          {% ren %}
          {% com %}
        LIQUID

        assert_completions(engine.completions(filename, 0, 6), {
          label: "render",
          kind: CompletionItemKinds::KEYWORD,
        })
        assert_completions(engine.completions(filename, 1, 6), {
          label: "comment",
          kind: CompletionItemKinds::KEYWORD,
        })
      end

      def test_cursor_on_tag?
        engine = make_engine(filename => <<~LIQUID)
          {% ren %}
          {% com %}
        LIQUID

        assert_completions(engine.completions(filename, 0, 6), {
          label: "render",
          kind: CompletionItemKinds::KEYWORD,
        })
        assert_completions(engine.completions(filename, 1, 6), {
          label: "comment",
          kind: CompletionItemKinds::KEYWORD,
        })
      end

      def test_complete_object
        engine = make_engine(filename => <<~LIQUID)
          {{ prod }}
          {{ all_ }}
        LIQUID

        assert_completions(engine.completions(filename, 0, 7), {
          label: "product",
          kind: CompletionItemKinds::VARIABLE,
        })
        assert_completions(engine.completions(filename, 1, 7), {
          label: "all_products",
          kind: CompletionItemKinds::VARIABLE,
        })
      end

      def test_about_to_type
        engine = make_engine(filename => "{{ }}")
        assert_completions(engine.completions(filename, 0, 3), {
          label: "all_products",
          kind: CompletionItemKinds::VARIABLE,
        })

        engine = make_engine(filename => "{% %}")
        assert_completions(engine.completions(filename, 0, 3), {
          label: "render",
          kind: CompletionItemKinds::KEYWORD,
        })
      end

      def test_out_of_bounds
        engine = make_engine(filename => "{{ prod }}")
        assert_empty(engine.completions(filename, 0, 8))
        assert_empty(engine.completions(filename, 0, 1))
      end

      def test_unique_completions
        engine = make_engine(filename => <<~LIQUID)
          {% assign product = all_products.first %}
          {{  }}
        LIQUID
        assert_equal(1, engine
          .completions(filename, 1, 3)
          .count { |y| y[:label] == "product" })
      end

      private

      def assert_completions(completion_items, item)
        completion_items = completion_items.map do |completion|
          # Ignore other fields (e.g. :documentation) to keep tests readable.
          completion.slice(:label, :kind)
        end

        assert_includes(completion_items, item)
      end

      def make_engine(files)
        storage = InMemoryStorage.new(files)
        CompletionEngine.new(storage)
      end

      def filename
        "layout/theme.liquid"
      end
    end
  end
end
