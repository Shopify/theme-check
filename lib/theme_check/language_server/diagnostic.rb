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
        if other.is_a?(Hash)
          to_h == other
        elsif other.is_a?(Diagnostic)
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

      def data
        path = offense&.theme_file&.path
        {
          path: path.to_s,
          uri: path && file_uri(path),
          version: offense&.version,
        }
      end
    end
  end
end
