# frozen_string_literal: true

module ThemeCheck
  module LanguageServer
    class Diagnostic
      include URIHelper

      attr_reader :offense

      def initialize(offense)
        @offense = offense
        @diagnostic = nil
      end

      def ==(other)
        case other
        when Hash, Diagnostic
          to_h == other.to_h
        else
          raise ArgumentError
        end
      end

      def to_h
        return @diagnostic unless @diagnostic.nil?
        @diagnostic = {
          source: "theme-check",
          code: code,
          message: message,
          range: range,
          severity: severity,
          data: data,
        }
        @diagnostic[:codeDescription] = code_description unless offense.doc.nil?
        @diagnostic
      end

      def to_s
        to_h.to_s
      end

      def single_file?
        offense.single_file?
      end

      def whole_theme?
        offense.whole_theme?
      end

      def correctable?
        offense.correctable?
      end

      def code
        offense.code_name
      end

      def message
        offense.message
      end

      def code_description
        {
          href: offense.doc,
        }
      end

      def severity
        case offense.severity
        when :error
          1
        when :suggestion
          2
        when :style
          3
        else
          4
        end
      end

      def range
        {
          start: {
            line: offense.start_row,
            character: offense.start_column,
          },
          end: {
            line: offense.end_row,
            character: offense.end_column,
          },
        }
      end

      def start_index
        offense.start_index
      end

      def end_index
        offense.end_index
      end

      def absolute_path
        @absolute_path ||= offense&.theme_file&.path
      end

      def relative_path
        @relative_path ||= offense&.theme_file&.relative_path
      end

      def uri
        @uri ||= absolute_path && file_uri(absolute_path)
      end

      def file_version
        @version ||= offense&.version
      end

      def data
        {
          absolute_path: absolute_path.to_s,
          relative_path: relative_path.to_s,
          uri: uri,
          version: file_version,
        }
      end
    end
  end
end
