# frozen_string_literal: true
module ThemeCheck
  class Offense < Struct.new(:check, :template, :node, :message)
    def line_number
      node&.line_number
    end

    def code
      template.excerpt(line_number) if line_number
    end

    def severity
      check.severity
    end

    def check_name
      check.class.name.demodulize
    end

    def doc
      check.doc
    end

    def location
      [template&.relative_path, line_number].compact.join(":")
    end

    def to_s
      if template
        "#{message} at #{location}"
      else
        message
      end
    end
  end
end
