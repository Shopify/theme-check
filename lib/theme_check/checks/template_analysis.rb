# frozen_string_literal: true
module ThemeCheck
  class TemplateAnalysis < LiquidCheck
    severity :suggestion
    category :liquid
    doc docs_url(__FILE__)

    def initialize(template_schema, shop_context)
      @shop_context = shop_context
      @liquid_context = {}
      template_schema.global_drops.each_pair do |name, schema|
        @liquid_context[name] = schema.new(shop_context: @shop_context);
      end
      super()
    end

    def on_for(node)
      collection_name = node.value.collection_name.name

      collection_drop_schema = @liquid_context[collection_name]
      return unless collection_drop_schema

      variable_name = node.value.variable_name
      lookups = node.value.collection_name.lookups
      lookup_drop_schemas = traverse_lookups(lookups, collection_drop_schema)
      lookup_drop_schemas.each do |schema|
        if schema.name == "Metafield"

        end
        puts "On for lookup: #{schema.name}, #{schema.lookup_name}"
      end

      @liquid_context[variable_name] = lookup_drop_schemas.last
    end

    def after_for(node)
      @liquid_context.delete(node.value.variable_name)
    end

    def on_variable(node)
      variable_name = node.value.name.name
      variable_drop_schema = @liquid_context[variable_name]
      return unless variable_drop_schema

      lookups = node.value.name.lookups
      lookup_drop_schemas = traverse_lookups(lookups, variable_drop_schema)
      lookup_drop_schemas.each do |schema|
        puts "On variable lookup: #{schema.name}, #{schema.lookup_name}"
      end
     end


    private

    def traverse_lookups(lookups, base_drop_schema)
      traversed_drop_schemas = [base_drop_schema]
      lookups.each do |lookup_name|
        parent_schema = traversed_drop_schemas.last
        traversed_drop_schemas << traversed_drop_schemas.last.property_by_name(lookup_name)&.new(shop_context: @shop_context, parent_schema: parent_schema, lookup_name: lookup_name)
      end

      traversed_drop_schemas
    end
  end
end
