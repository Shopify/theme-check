# frozen_string_literal: true

module ThemeCheck
  module LanguageServer
    module DiagnosticsHelper
      class << self
        def offense_to_diagnostic(offense)
          diagnostic = {
            code: offense.code_name,
            message: offense.message,
            range: range(offense),
            severity: severity(offense),
            source: "theme-check",
          }
          diagnostic["codeDescription"] = code_description(offense) unless offense.doc.nil?
          diagnostic
        end

        private

        def code_description(offense)
          {
            href: offense.doc,
          }
        end

        def severity(offense)
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

        def range(offense)
          {
            start: {
              line: offense.start_line,
              character: offense.start_column,
            },
            end: {
              line: offense.end_line,
              character: offense.end_column,
            },
          }
        end
      end
    end
  end
end
