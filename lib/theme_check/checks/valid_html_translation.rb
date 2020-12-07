# frozen_string_literal: true

require 'nokogiri'

module ThemeCheck
  class ValidHTMLTranslation < JsonCheck
    severity :suggestion

    def on_file(file)
      return unless file.name.starts_with?("locales/")
      return unless file.content.is_a?(Hash)

      visit_nested(file.content)
    end

    private

    def key_is_html(keys)
      pluralized_key = keys[-2] if keys.length > 1
      keys[-1].end_with?('_html') || pluralized_key.end_with?('_html')
    end

    def parse_and_add_offence(key, value)
      return unless value.is_a?(String)

      html = Nokogiri::XML.parse(value)
      unless html.errors.empty?
        add_offense("'#{key}' contains invalid HTML: #{html.errors.join(', ')}")
      end
    end

    def visit_nested(value, keys = [])
      if value.is_a?(Hash)
        value.each do |k, v|
          visit_nested(v, keys << k)
        end
      elsif key_is_html(keys)
        parse_and_add_offence(keys.join(': '), value)
      end
    end
  end
end
