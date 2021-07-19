# frozen_string_literal: true
module ThemeCheck
  class PaginationSize < LiquidCheck
    severity :suggestion
    categories :performance
    doc docs_url(__FILE__)

    attr_reader :min_size
    attr_reader :max_size

    def initialize(min_size: 1, max_size: 50)
      @min_size = min_size
      @max_size = max_size
    end

    def on_document(_node)
      @paginations = {}
      @schema_settings = {}
    end

    def on_paginate(node)
      size = node.value.page_size
      unless @paginations.key?(size)
        @paginations[size] = []
      end
      @paginations[size].push(node)
    end

    def on_schema(node)
      schema = JSON.parse(node.value.nodelist.join)

      if (settings = schema["settings"])
        @schema_settings = settings
      end
    rescue JSON::ParserError
      # Ignored, handled in ValidSchema.
    end

    def after_document(_node)
      @paginations.each_pair do |size, nodes|
        numerical_size = if size.is_a?(Numeric)
          size
        else
          get_setting_default_value(size.lookups.last)
        end
        if numerical_size.nil?
          nodes.each { |node| add_offense("Default pagination size should be defined in the section settings", node: node) }
        elsif numerical_size > @max_size || numerical_size < @min_size || !numerical_size.is_a?(Integer)
          nodes.each { |node| add_offense("Pagination size must be a positive integer between #{@min_size} and #{@max_size}", node: node) }
        end
      end
    end

    private

    def get_setting_default_value(setting_id)
      setting = @schema_settings.select { |s| s['id'] == setting_id }
      unless setting.empty?
        return setting.last['default']
      end
      # Setting does not exist
      nil
    end
  end
end
