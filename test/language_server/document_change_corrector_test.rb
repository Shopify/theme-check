# frozen_string_literal: true
require "test_helper"

module PlatformosCheck
  module LanguageServer
    class DocumentChangeCorrectorTest < Minitest::Test
      include URIHelper
      include JsonHelpers

      def setup
        @node = find(root_node("{{x}} "), &:variable?)
        @corrector = DocumentChangeCorrector.new
      end

      def test_could_pass_for_a_corrector
        document_change_corrector_methods = DocumentChangeCorrector.new.methods
        corrector_methods = Corrector.new(theme_file: nil).methods
        difference = corrector_methods - document_change_corrector_methods
        assert_empty(difference, <<~EXPECTED)
          Expected the following methods to be implemented in DocumentChangeCorrector:

          #{pretty_print(difference)}

          If this test is failing because you are adding a new method to Corrector,
          it should be possible to do the same thing in the Language Server.

          For more details on how we correct diagnostics in the language server, see our docs file on the subject:

          docs/language_server/how_to_correct_code_with_code_actions_and_execute_command.md
        EXPECTED

        difference = document_change_corrector_methods - corrector_methods - [:file_path, :file_uri, :document_changes]
        assert_empty(difference, <<~EXPECTED)
          Expected the following methods to be implemented in Corrector:

          #{pretty_print(difference)}

          If this test is failing because you are adding a new method to DocumentChangeCorrector,
          it should be possible to do the same thing outside the language server.
        EXPECTED
      end

      def test_insert_before
        @corrector.insert_before(@node, ' ')
        assert_equal(2, @node.start_column)
        assert_equal(
          [
            {
              textDocument: {
                uri: file_uri(@node.theme_file.path),
                version: nil,
              },
              edits: [{
                range: range(0, 2, 0, 2),
                newText: ' ',
              }],
            },
          ],
          @corrector.document_changes
        )
      end

      def test_insert_before_character_range
        @corrector.insert_before(@node, ' ', 1...5)
        assert_equal(2, @node.start_column)
        assert_equal(
          [
            {
              textDocument: {
                uri: file_uri(@node.theme_file.path),
                version: nil,
              },
              edits: [{
                range: range(0, 1, 0, 1),
                newText: ' ',
              }],
            },
          ],
          @corrector.document_changes
        )
      end

      def test_insert_after
        @corrector.insert_after(@node, ' ')
        assert_equal(3, @node.end_column)
        assert_equal(
          [
            {
              textDocument: {
                uri: file_uri(@node.theme_file.path),
                version: nil,
              },
              edits: [{
                range: range(0, 3, 0, 3),
                newText: ' ',
              }],
            },
          ],
          @corrector.document_changes
        )
      end

      def test_insert_after_character_range
        @corrector.insert_after(@node, ' ', 0...5)
        assert_equal(3, @node.end_column)
        assert_equal(
          [
            {
              textDocument: {
                uri: file_uri(@node.theme_file.path),
                version: nil,
              },
              edits: [{
                range: range(0, 5, 0, 5),
                newText: ' ',
              }],
            },
          ],
          @corrector.document_changes
        )
      end

      def test_replace
        @corrector.replace(@node, 'y')
        assert_equal(3, @node.end_column)
        assert_equal(
          [
            {
              textDocument: {
                uri: file_uri(@node.theme_file.path),
                version: nil,
              },
              edits: [{
                range: range(0, 2, 0, 3),
                newText: 'y',
              }],
            },
          ],
          @corrector.document_changes
        )
      end

      def test_replace_character_range
        @corrector.replace(@node, 'y', 0...5)
        assert_equal(3, @node.end_column)
        assert_equal(
          [
            {
              textDocument: {
                uri: file_uri(@node.theme_file.path),
                version: nil,
              },
              edits: [{
                range: range(0, 0, 0, 5),
                newText: 'y',
              }],
            },
          ],
          @corrector.document_changes
        )
      end

      def test_remove
        @corrector.remove(@node)
        assert_equal(3, @node.end_column)
        assert_equal(
          [
            {
              textDocument: {
                uri: file_uri(@node.theme_file.path),
                version: nil,
              },
              edits: [{
                range: range(0, 0, 0, 5),
                newText: '',
              }],
            },
          ],
          @corrector.document_changes
        )
      end

      def test_replace_inner_markup
        node = find(root_node(<<~LIQUID)) { |n| n.type_name == :schema }
          {% schema %}Hello Muffin{% endschema %}
          012345678901234567890123456789
        LIQUID
        corrector = DocumentChangeCorrector.new
        corrector.replace_inner_markup(node, "Hello cookies!")
        assert_equal(
          [{
            textDocument: {
              uri: file_uri(node.theme_file.path),
              version: nil,
            },
            edits: [{
              range: range(0, 12, 0, 24),
              newText: 'Hello cookies!',
            }],
          }],
          corrector.document_changes,
        )
      end

      def test_wrap
        @corrector.wrap(@node, '<', '>')
        assert_equal(3, @node.end_column)
        assert_equal(
          [
            {
              textDocument: {
                uri: file_uri(@node.theme_file.path),
                version: nil,
              },
              edits: [{
                range: range(0, 2, 0, 3),
                newText: '<x>',
              }],
            },
          ],
          @corrector.document_changes
        )
      end

      def test_create_file
        @corrector.create_file(@node.theme_file.storage, 'test.liquid', 'hello world')
        assert_equal(
          [
            {
              kind: 'create',
              uri: file_uri(@node.theme_file.storage.path('test.liquid')),
            },
            {
              textDocument: {
                uri: file_uri(@node.theme_file.storage.path('test.liquid')),
                version: nil,
              },
              edits: [
                {
                  range: range(0, 0, 0, 0),
                  newText: 'hello world',
                },
              ],
            },
          ],
          @corrector.document_changes
        )
      end

      def test_remove_file
        @corrector.remove_file(@node.theme_file.storage, 'test.liquid')
        assert_equal(
          [
            {
              kind: 'delete',
              uri: file_uri(@node.theme_file.storage.path('test.liquid')),
            },
          ],
          @corrector.document_changes
        )
      end

      def test_mkdir
        @corrector.mkdir(@node.theme_file.storage, 'test.liquid')
        assert_equal(
          [
            {
              kind: 'create',
              uri: file_uri(@node.theme_file.storage.path('test.liquid').join('tmp')),
            },
            {
              kind: 'delete',
              uri: file_uri(@node.theme_file.storage.path('test.liquid').join('tmp')),
            },
          ],
          @corrector.document_changes
        )
      end

      def test_add_remove_translation
        contents = '{ "a": "b" }'
        storage = make_storage("foo.json" => contents)
        file = JsonFile.new('foo.json', storage)
        @corrector.add_translation(file, "hello", "world")
        @corrector.remove_translation(file, "a")
        assert_equal(
          [
            {
              textDocument: {
                uri: file_uri(storage.path('foo.json')),
                version: nil,
              },
              edits: [{
                range: {
                  start: { line: 0, character: 0 },
                  end: { line: 0, character: contents.size - 1 },
                },
                newText: JSON.pretty_generate({ hello: "world" }),
              }],
            },
          ],
          @corrector.document_changes
        )
      end

      def test_replace_json_body
        node = find(root_node(<<~LIQUID)) { |n| n.type_name == :schema }
          {% schema %}
            {}
          {% endschema %}
        LIQUID
        corrector = DocumentChangeCorrector.new

        # Simulate doing multiple corrector calls on the _same_ node.
        json = node.inner_json
        SchemaHelper.set(json, 'a.b', 1)
        corrector.replace_inner_json(node, json)
        SchemaHelper.set(json, 'a.c', 2)
        corrector.replace_inner_json(node, json)

        # We expect only ONE change for all those replace_inner_json calls
        assert_equal(
          [{
            textDocument: {
              uri: file_uri(node.theme_file.path),
              version: nil,
            },
            edits: [{
              range: range(0, 12, 2, 0),
              newText: pretty_json(json, start_level: 1),
            }],
          }],
          corrector.document_changes,
        )
      end

      private

      def root_node(code)
        theme_file = parse_liquid(code)
        LiquidNode.new(theme_file.root, nil, theme_file)
      end

      def find(node, &block)
        return node if block.call(node)
        return nil if node.children.nil? || node.children.empty?
        node.children
          .map { |n| find(n, &block) }
          .find { |n| !n.nil? }
      end

      def range(start_row, start_column, end_row, end_column)
        {
          start: { line: start_row, character: start_column },
          end: { line: end_row, character: end_column },
        }
      end
    end
  end
end
