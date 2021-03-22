# frozen_string_literal: true
module ThemeCheck
  # Reports errors when trying to use parser-blocking script tags
  class ImgWidthAndHeight < LiquidCheck
    include RegexHelpers
    severity :error
    categories :liquid, :performance
    doc docs_url(__FILE__)

    # Not implemented with lookbehinds and lookaheads because performance was shit!
    IMG_TAG = /<img#{HTML_ATTRIBUTES}>/oxim
    SRC_ATTRIBUTE = /\s(src)=(#{QUOTED_LIQUID_ATTRIBUTE})/oxim
    WIDTH_ATTRIBUTE = /\s(width)=(#{QUOTED_LIQUID_ATTRIBUTE})/oxim
    HEIGHT_ATTRIBUTE = /\s(height)=(#{QUOTED_LIQUID_ATTRIBUTE})/oxim

    FIELDS = [WIDTH_ATTRIBUTE, HEIGHT_ATTRIBUTE]
    ENDS_IN_CSS_UNIT = /(cm|mm|in|px|pt|pc|em|ex|ch|rem|vw|vh|vmin|vmax|%)$/i

    def on_document(node)
      @source = node.template.source
      @node = node
      record_offenses
    end

    private

    def record_offenses
      matches(@source, IMG_TAG).each do |img_match|
        next unless img_match[0] =~ SRC_ATTRIBUTE
        record_missing_field_offenses(img_match)
        record_units_in_field_offenses(img_match)
      end
    end

    def record_missing_field_offenses(img_match)
      width = WIDTH_ATTRIBUTE.match(img_match[0])
      height = HEIGHT_ATTRIBUTE.match(img_match[0])
      return if width.present? && height.present?
      missing_width = width.nil?
      missing_height = height.nil?
      error_message = if missing_width && missing_height
        "Missing width and height attributes"
      elsif missing_width
        "Missing width attribute"
      elsif missing_height
        "Missing height attribute"
      end

      add_offense(
        error_message,
        node: @node,
        markup: img_match[0],
        line_number: @source[0...img_match.begin(0)].count("\n") + 1
      )
    end

    def record_units_in_field_offenses(img_match)
      FIELDS.each do |field|
        field_match = field.match(img_match[0])
        next if field_match.nil?
        value = field_match[2].gsub(START_OR_END_QUOTE, '')
        next unless value =~ ENDS_IN_CSS_UNIT
        value_without_units = value.gsub(ENDS_IN_CSS_UNIT, '')
        start = img_match.begin(0) + field_match.begin(2)
        add_offense(
          "The #{field_match[1]} attribute does not take units. Replace with \"#{value_without_units}\".",
          node: @node,
          markup: value,
          line_number: @source[0...start].count("\n") + 1
        )
      end
    end
  end
end
