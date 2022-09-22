# frozen_string_literal: true
module ThemeCheck
  class MetafieldAnalysis < LiquidCheck
    severity :suggestion
    category :liquid
    doc docs_url(__FILE__)

    def initialize()
      add_resource(
        ThemeCheck::Resource.new(
          name: 'product',
          resource_type: "product",
          metafields: []
        )
      )
      super
    end

    def on_variable(node)
     resource = resources.find { |resource| resource.name == node.value.name.name }
     return unless resource
     lookups = node.value.name.lookups
     metafield = resource.metafield_from_lookups(lookups: lookups)

     if metafield
      resource.metafields.push(metafield)
     end
    end

    def on_for(node)
      name = node.value.collection_name.name
      resource = resources.find { |resource| resource.name == name }
      return unless resource

      lookups = node.value.collection_name.lookups
      metafield = resource.metafield_from_lookups(lookups: lookups)
      if metafield
        resource.metafields.push(metafield)
        referenced_resource = metafield.referenced_resource(name: node.value.variable_name)
        add_resource(referenced_resource) unless referenced_resource.nil?
      end
    end

    def after_for(node)
    end

    def on_variable_lookup(node)
      #@test.push('on_variable_lookup')
    end
  end
end
