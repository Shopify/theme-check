module ThemeCheck
  class Offense < Struct.new(:check, :template, :node, :message)
    def line_number
      node&.line_number
    end

    def severity
      check.severity
    end

    def doc
      check.doc
    end

    def to_s
      out = +''
      out << "#{message} at #{template}"
      out << ":#{line_number}" if line_number
      out
    end
  end
end
