# frozen_string_literal: true
module ThemeCheck
  # Reports errors when too much JS is being referenced from a Theme App
  # Extension block
  class AssetSizeAppBlockJavaScript < LiquidCheck
    severity :error
    category :performance
    doc docs_url(__FILE__)

    # Don't allow this check to be disabled with a comment,
    # since we need to be able to enforce this server-side
    can_disable false

    attr_reader :threshold_in_bytes

    def initialize(threshold_in_bytes: 10_000)
      @threshold_in_bytes = threshold_in_bytes
    end

    def on_schema(node)
      schema = JSON.parse(node.value.nodelist.join)

      if (javascript = schema["javascript"])
        size = asset_size(javascript)
        if size && size > threshold_in_bytes
          add_offense(
            "JavaScript in Theme App Extension blocks exceeds compressed size threshold (#{threshold_in_bytes} Bytes)",
            node: node
          )
        end
      end
    rescue JSON::ParserError
      # Ignored, handled in ValidSchema.
    end

    private

    def asset_size(name)
      asset = @theme["assets/#{name}"]
      return if asset.nil?
      asset.gzipped_size
    end
  end
end
