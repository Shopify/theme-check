# frozen_string_literal: true

module ThemeCheck
  module LanguageServer
    class DocumentChangeCorrector
      include URIHelper

      def initialize
        @text_document_edits = {}
        @create_files = []
        @rename_files = []
        @delete_files = []
      end

      def document_changes
        @create_files + @rename_files + @text_document_edits.values + @delete_files
      end

      # @param node [Node]
      def insert_before(node, content)
        edits(node) << {
          range: { start: start_position(node), end: start_position(node) },
          newText: content,
        }
      end

      # @param node [Node]
      def insert_after(node, content)
        edits(node) << {
          range: { start: end_position(node), end: end_position(node) },
          newText: content,
        }
      end

      def replace(node, content)
        edits(node) << {
          range: range(node),
          newText: content,
        }
      end

      def wrap(node, insert_before, insert_after)
        edits(node) << {
          range: range(node),
          newText: insert_before + node.markup + insert_after,
        }
      end

      def create(storage, relative_path, contents = nil, overwrite: false)
        uri = file_uri(storage.path(relative_path))
        @create_files << create_file(uri, overwrite)
        return if contents.nil?
        text_document = { uri: uri, version: nil }
        @text_document_edits[text_document] = {
          textDocument: text_document,
          edits: [{
            range: {
              start: { line: 0, character: 0 },
              end: { line: 0, character: 0 },
            },
            newText: contents,
          }],
        }
      end

      def create_file(uri, overwrite = false)
        result = {}
        result[:kind] = 'create'
        result[:uri] = uri
        result[:options] = { overwrite: overwrite } if overwrite
        result
      end

      def remove(storage, relative_path)
        @delete_files << {
          kind: 'delete',
          uri: file_uri(storage.path(relative_path)),
        }
      end

      def mkdir(storage, relative_path)
        path = Pathname.new(relative_path).join("tmp").to_s
        # The LSP doesn't have a concept for directories, so what we
        # do is create a file and then delete it.
        #
        # It does the job :upside_down_smile:.
        create(storage, path)
        remove(storage, path)
      end

      # @param file [JsonFile]
      # @param key_path [Array]
      def add_translation(file, key_path, value)
        hash = file.content
        key_path = key_path.split('.') if key_path.is_a?(String)
        key_path.each_with_index.reduce(hash) do |pointer, (token, index)|
          if index == key_path.size - 1
            pointer[token] = value
          elsif !pointer.key?(token)
            pointer[token] = {}
          end
          pointer[token]
        end
        # simpler to just overwrite it.
        create(file.storage, file.relative_path, JSON.pretty_generate(hash), overwrite: true)
      end

      private

      # @param node [Node]
      def text_document_edit(node)
        text_document = to_text_document(node)
        @text_document_edits[text_document] ||= {
          textDocument: text_document,
          edits: [],
        }
      end

      def edits(node)
        text_document_edit(node)[:edits]
      end

      def to_text_document(node)
        {
          uri: file_uri(node.theme_file&.path),
          version: node.theme_file&.version,
        }
      end

      def absolute_path(node)
        node.theme_file&.path
      end

      # @param node [ThemeCheck::Node]
      def range(node)
        {
          start: start_position(node),
          end: end_position(node),
        }
      end

      def start_position(node)
        {
          line: node.start_row,
          character: node.start_column,
        }
      end

      def end_position(node)
        {
          line: node.end_row,
          character: node.end_column,
        }
      end
    end
  end
end
