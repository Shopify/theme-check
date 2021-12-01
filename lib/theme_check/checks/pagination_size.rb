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
      schema = node.inner_json
      return if schema.nil?

      if (settings = schema["settings"])
        @schema_settings = settings
      end
    end

    ##
    # Section settings look like:
    #   #<Liquid::VariableLookup:0x00007fd699c50c48 @name="section", @lookups=["settings", "products_per_page"], @command_flags=0>
    def size_is_a_section_setting?(size)
      size.is_a?(Liquid::VariableLookup) &&
        size.name == 'section' &&
        size.lookups.first == 'settings'
    end

    ##
    # We'll work with either an explicit value, or the default value of the section setting.
    def get_value(size)
      return size if size.is_a?(Numeric)
      return get_setting_default_value(size) if size_is_a_section_setting?(size)
    end

    def after_document(_node)
      @paginations.each_pair do |size, nodes|
        # Validate presence of default section setting.
        if size_is_a_section_setting?(size) && !get_setting_default_value(size)
          nodes.each { |node| add_offense("Default pagination size should be defined in the section settings", node: node) }
        end

        # Validate if size is within range.
        next unless (numerical_size = get_value(size))
        if numerical_size > @max_size || numerical_size < @min_size || !numerical_size.is_a?(Integer)
          nodes.each { |node| add_offense("Pagination size must be a positive integer between #{@min_size} and #{@max_size}", node: node) }
        end
      end
    end

    private

    def get_setting_default_value(variable_lookup)
      setting = @schema_settings.select { |s| s['id'] == variable_lookup.lookups.last }

      # Setting does not exist.
      return nil if setting.empty?

      default_value = setting.last['default'].to_i
      return nil if default_value == 0

      default_value
    end
  end
end
