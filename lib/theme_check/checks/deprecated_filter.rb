# frozen_string_literal: true

module ThemeCheck
  class DeprecatedFilter < LiquidCheck
    doc docs_url(__FILE__)
    category :liquid
    severity :suggestion

    # The image_url filter does not accept width or height values
    # greater than this numbr.
    MAX_SIZE = 5760
    SIZE_REGEX = /^\d*x\d*$/
    NAMED_SIZES = {
      "pico" => 16,
      "icon" => 32,
      "thumb" => 50,
      "small" => 100,
      "compact" => 160,
      "medium" => 240,
      "large" => 480,
      "grande" => 600,
      "original" => 1024,
      "master" => nil,
    }

    def on_variable(node)
      used_filters = node.filters.map { |name, *_rest| name }
      used_filters.each do |filter|
        alternatives = ShopifyLiquid::DeprecatedFilter.alternatives(filter)
        next unless alternatives

        case filter
        when 'img_url'
          add_img_url_offense(node)
        else
          add_default_offense(node, filter, alternatives)
        end
      end
    end

    def add_default_offense(node, filter, alternatives)
      alternatives = alternatives.map { |alt| "`#{alt}`" }
      add_offense(
        "Deprecated filter `#{filter}`, consider using an alternative: #{alternatives.join(', ')}",
        node: node,
      )
    end

    def add_img_url_offense(node)
      img_url_filter = node.filters.find { |filter| filter[0] == "img_url" }
      _name, img_url_filter_size, img_url_filter_props = img_url_filter
      size_spec = img_url_filter_size&.dig(0)
      scale = img_url_filter_props&.delete("scale")

      # Can't correct those.
      return add_default_offense(node, 'img_url', ['image_url']) unless
        (size_spec.nil? || size_spec.is_a?(String)) &&
          (scale.nil? || scale.is_a?(Numeric))

      return add_default_offense(node, 'img_url', ['image_url']) if
        size_spec.is_a?(String) &&
          size_spec !~ SIZE_REGEX &&
          !NAMED_SIZES.key?(size_spec)

      node_source = node.markup

      node_start_index = node.start_index
      match = node_source.match(/img_url[^|]*/)
      img_url_character_range =
        (node_start_index + match.begin(0))...(node_start_index + match.end(0))

      scale = (scale || 1).to_i
      width, height = if size_spec.nil?
        [100, 100]
      elsif NAMED_SIZES.key?(size_spec)
        [NAMED_SIZES[size_spec], NAMED_SIZES[size_spec]]
      else
        size_spec.split('x')
      end.map { |v| v.to_i * scale }

      image_url_filter_params = [
        width && width > 0 ? "width: #{[width, MAX_SIZE].min}" : nil,
        height && height > 0 ? "height: #{[height, MAX_SIZE].min}" : nil,
      ]
      image_url_filter_params += (img_url_filter_props || {})
        .map do |k, v|
          case v
          when Liquid::VariableLookup
            "#{k}: #{v.name}"
          when String
            "#{k}: '#{v}'"
          else
            "#{k}: #{v}"
          end
        end
      image_url_filter_params = image_url_filter_params
        .reject(&:nil?)
        .join(", ")

      trailing_whitespace = match[0].match(/\s*\Z/)[0]

      image_url_filter = "image_url"
      image_url_filter += ": " + image_url_filter_params unless image_url_filter_params.empty?
      image_url_filter += trailing_whitespace

      add_offense(
        "Deprecated filter `img_url`, consider using `image_url`",
        node: node,
        markup: match[0]
      ) do |corrector|
        corrector.replace(
          node,
          image_url_filter,
          img_url_character_range,
        )
      end

    # If anything goes wrong, fail gracefully by returning the default offense.
    rescue
      add_default_offense(node, 'img_url', ['image_url'])
    end
  end
end
