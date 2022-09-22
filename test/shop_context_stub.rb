class ShopContextStub
  def self.metaobject_definitions
    {
      1 => {
        type: "team_member"
      },
      2 => {
        type: "project"
      }
    }
  end

  def self.metafield_definitions
    ## hash key in format <owner_type>.<namespace>.<key>
    {
      "Product.custom.created_by" => {
        type: "metaobject_reference",
        validations: [{name: "metaobject_definition_id", value: 1}]
      },
      "ContentEntry.team_member.name" => {
        type: "single_line_text_field",
        validations: [],
      },
      "ContentEntry.team_member.projects" => {
        type: "metaobject_reference",
        validations: [{name: "metaobject_definition_id", value: 2}]
      },
      "ContentEntry.project.title" => {
        type: "single_line_text_field",
        validations: []
      }
    }
  end

  def self.metafield_definition(owner_type:, namespace:, key:)
    self.metafield_definitions["#{owner_type}.#{namespace}.#{key}"]
  end

  def self.metaobject_definition_by_id(id:)
    self.metaobject_definitions[id]
  end

  def self.metaobject_definition_by_type(type:)
    binding.pry
  end
end
