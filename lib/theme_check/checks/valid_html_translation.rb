# frozen_string_literal: true

require 'nokogumbo'

module ThemeCheck
  class ValidHTMLTranslation < JsonCheck
    severity :suggestion

    def on_file(file)
      return unless file.name.starts_with?("locales/")
      return unless file.content.is_a?(Hash)

      visit_nested(file.content)
    end

    private

    def html_key?(keys)
      pluralized_key = keys[-2] if keys.length > 1
      keys[-1].end_with?('_html') || pluralized_key.end_with?('_html')
    end

    def parse_and_add_offence(key, value)
      return unless value.is_a?(String)

      html = Nokogiri::HTML5.fragment(value, max_errors: -1)
      unless html.errors.empty?
        err_msg = html.errors.join("\n")
        add_offense("'#{key}' contains invalid HTML:\n#{err_msg}")
      end
    end

    def visit_nested(value, keys = [])
      if value.is_a?(Hash)
        value.each do |k, v|
          visit_nested(v, keys + [k])
        end
      elsif html_key?(keys)
        parse_and_add_offence(keys.join('.'), value)
      end
    end
  end
end
