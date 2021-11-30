# frozen_string_literal: true

module ThemeCheck
  module LanguageServer
    class DocumentChangeCorrector
      include URIHelper
      include JsonHelpers

      def initialize
        @json_edits = {}
        @json_file_edits = {}
        @text_document_edits = {}
        @create_files = []
        @rename_files = []
        @delete_files = []
      end

      def document_changes
        apply_json_edits
        apply_json_file_edits
        @create_files + @rename_files + @text_document_edits.values + @delete_files
      end

      # @param node [Node]
      def insert_before(node, content, character_range = nil)
        position = character_range_position(node, character_range) if character_range
        edits(node) << {
          range: {
            start: start_location(position || node),
            end: start_location(position || node),
          },
          newText: content,
        }
      end

      # @param node [Node]
      def insert_after(node, content, character_range = nil)
        position = character_range_position(node, character_range) if character_range
        edits(node) << {
          range: {
            start: end_location(position || node),
            end: end_location(position || node),
          },
          newText: content,
        }
      end

      def replace(node, content, character_range = nil)
        position = character_range_position(node, character_range) if character_range
        edits(node) << {
          range: range(position || node),
          newText: content,
        }
      end

      # @param node [LiquidNode]
      def remove(node)
        edits(node) << {
          range: {
            start: { line: node.outer_markup_start_row, character: node.outer_markup_start_column },
            end: { line: node.outer_markup_end_row, character: node.outer_markup_end_column },
          },
          newText: '',
        }
      end

      def replace_inner_markup(node, content)
        edits(node) << {
          range: {
            start: {
              line: node.inner_markup_start_row,
              character: node.inner_markup_start_column,
            },
            end: {
              line: node.inner_markup_end_row,
              character: node.inner_markup_end_column,
            },
          },
          newText: content,
        }
      end

      def replace_inner_json(node, json, **pretty_json_opts)
        # Kind of brittle alert: We're assuming that modifications are
        # made directly on the same json hash (e.g. schema). As such,
        # if this assumption is true, then it follows that the
        # "correct" JSON is the _last_ one that we defined.
        #
        # We're going to append those changes to the text edit when
        # we're done.
        #
        # We're doing this because no language client will accept
        # text modifications that occur on the same range. So we need
        # to dedup our JSON edits for the client to accept our change.
        #
        # What we're doing here is overwriting the json edit for a
        # node to the latest one that is called. If all the edits
        # occur on the same hash, this final hash will have all the
        # edits in it.
        @json_edits[node] = [json, pretty_json_opts]
      end

      def wrap(node, insert_before, insert_after)
        edits(node) << {
          range: range(node),
          newText: insert_before + node.markup + insert_after,
        }
      end

      def create_file(storage, relative_path, contents = nil, overwrite: false)
        uri = file_uri(storage.path(relative_path))
        @create_files << create_file_change(uri, overwrite)
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

      def remove_file(storage, relative_path)
        uri = file_uri(storage.path(relative_path))
        @delete_files << delete_file_change(uri)
      end

      def mkdir(storage, relative_path)
        path = Pathname.new(relative_path).join("tmp").to_s
        # The LSP doesn't have a concept for directories, so what we
        # do is create a file and then delete it.
        #
        # It does the job :upside_down_smile:.
        create_file(storage, path)
        remove_file(storage, path)
      end

      def add_translation(file, path, value)
        raise ArgumentError unless file.is_a?(JsonFile)
        hash = file.content
        SchemaHelper.set(hash, path, value)
        @json_file_edits[file] = hash
      end

      def remove_translation(file, path)
        raise ArgumentError unless file.is_a?(JsonFile)
        hash = file.content
        SchemaHelper.delete(hash, path)
        @json_file_edits[file] = hash
      end

      private

      def apply_json_edits
        @json_edits.each do |node, (json, pretty_json_opts)|
          replace_inner_markup(node, pretty_json(json, **pretty_json_opts))
        end
      end

      def apply_json_file_edits
        @json_file_edits.each do |file, hash|
          replace_entire_file(file, JSON.pretty_generate(hash))
        end
      end

      def replace_entire_file(file, contents)
        text_document = to_text_document(file)
        position = ThemeCheck::StrictPosition.new(file.source, file.source, 0)
        @text_document_edits[text_document] = {
          textDocument: text_document,
          edits: [{
            range: {
              start: { line: 0, character: 0 },
              end: { line: position.end_row, character: position.end_column },
            },
            newText: contents,
          }],
        }
      end

      # @param node [Node]
      def text_document_edit(node)
        text_document = to_text_document(node)
        @text_document_edits[text_document] ||= {
          textDocument: text_document,
          edits: [],
        }
      end

      def create_file_change(uri, overwrite = false)
        change = {}
        change[:kind] = 'create'
        change[:uri] = uri
        change[:options] = { overwrite: overwrite } if overwrite
        change
      end

      def delete_file_change(uri)
        {
          kind: 'delete',
          uri: uri,
        }
      end

      def edits(node)
        text_document_edit(node)[:edits]
      end

      def to_text_document(thing)
        case thing
        when Node
          {
            uri: file_uri(thing.theme_file&.path),
            version: thing.theme_file&.version,
          }
        when ThemeFile
          {
            uri: file_uri(thing.path),
            version: thing.version,
          }
        else
          raise ArgumentError
        end
      end

      def absolute_path(node)
        node.theme_file&.path
      end

      def character_range_position(node, character_range)
        return unless character_range
        source = node.theme_file.source
        StrictPosition.new(
          source[character_range],
          source,
          character_range.begin,
        )
      end

      # @param node [ThemeCheck::Node]
      def range(node)
        {
          start: start_location(node),
          end: end_location(node),
        }
      end

      def start_location(node)
        {
          line: node.start_row,
          character: node.start_column,
        }
      end

      def end_location(node)
        {
          line: node.end_row,
          character: node.end_column,
        }
      end
    end
  end
end
