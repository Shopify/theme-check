# Liquid check API

For checking the Liquid code in `.liquid` files.

All code inside `{% ... %}` or `{{ ... }}` is Liquid code.

Liquid files are parsed using the Liquid parser, by consequence you will get Liquid nodes (tags, blocks) in your callback methods. Check the Liquid source for details on those nodes: [Liquid source][liquidsource].


```ruby
module ThemeCheck
  class MyCheckName < LiquidCheck
    category :liquid,
    # A check can belong to multiple categories. Valid ones:
    categories :translation, :performance
    severity :suggestion # :error or :style

    def on_document(node)
      # Called with the root node of all templates
      node.value    # is the original Liquid object for this node. See Liquid source code for details.
      node.template # is the template being analyzed, See lib/theme_check/template.rb.
      node.parent   # is the parent node.
      node.children # are the children nodes.
      # See lib/theme_check/node.rb for more helper methods
      theme # Gives you access to all the templates in the theme. See lib/theme_check/theme.rb.
    end

    def on_node(node)
      # Called for every node
    end

    def on_tag(node)
      # Called for each tag (if, include, for, assign, etc.)
    end

    def after_tag(node)
      # Called after the tag children have been visited
      
      # If you find an issue, add an offense:
      add_offense("Describe the problem...", node: node)
      # Or, if the offense is related to the whole template:
      add_offense("Describe the problem...", template: node.template)
    end

    def on_assign(node)
      # Called only for {% assign ... %} tags
    end

    def on_string(node)
      # Called for every `String` (including inside if conditions).
      if node.parent.block?
        # If parent is a block, `node.value` is a String written directly to the output when
        # the template is rendered.
      end
    end

    def on_variable(node)
      # Called for each {{ ... }}
    end

    def on_error(exception)
      # Called each time a Liquid exception is raised while parsing the template
    end

    def on_end
      # A special callback after we're done visiting all the files of the theme
    end

    # Each type of node has a corresponding `on_node_class_name` & `after_node_class_name`
    # A few common examples:
    # on_capture(node)
    # on_case(node)
    # on_comment(node)
    # on_if(node)
    # on_condition(node)
    # on_else_condition(node)
    # on_for(node)
    # on_form(node)
    # on_include(node)
    # on_integer(node)
    # on_layout(node)
    # on_method_literal(node)
    # on_paginate(node)
    # on_range(node)
    # on_render(node)
    # on_schema(node)
    # on_section(node)
    # on_style(node)
    # on_unless(node)
    # on_variable_lookup(node)
  end
end
```

## Resources

- [Liquid source][liquidsource]

[liquidsource]: https://github.com/Shopify/liquid/tree/master/lib/liquid
