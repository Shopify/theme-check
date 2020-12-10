# Contributing to Theme Check

We love receiving pull requests!

## Standards

* Checks should do one thing, and do it well.
* PR should explain what the feature does, and why the change exists.
* PR should include any carrier specific documentation explaining how it works.
* Code _must_ be tested.
* Be consistent. Write clean code that follows [Ruby community standards](https://github.com/bbatsov/ruby-style-guide).
* Code should be generic and reusable.

## How to contribute

1. Fork it ( https://github.com/Shopify/theme-check/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Running Tests

> bundle install
> bundle exec rake

## Creating a new "Check"

Under `lib/theme_check/checks`, create new Ruby file with a unique name describing what you want to check for.

```ruby
module ThemeCheck
  # Does one thing, and does it well!
  # NOTE: inherit from JsonCheck to implement a JSON based check.
  class MyCheckName < LiquidCheck
    severity :suggestion # :error or :style
    doc "https://..."    # Optional link to doc

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

    def on_error(exception)
      # Called each time a Liquid exception is raised while parsing the template
    end

    def on_end
      # A special callback after we're done visiting all the templates
    end

    # Each type of node has a corresponding `on_node_class_name` & `after_node_class_name`
    # A few common examples:
    # on_block_body(node)
    # on_capture(node)
    # on_case(node)
    # on_comment(node)
    # on_condition(node)
    # on_document(node)
    # on_else_condition(node)
    # on_for(node)
    # on_form(node)
    # on_if(node)
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
    # on_variable(node)
    # on_variable_lookup(node)
  end
end
```

Add the new check to `config/default.yml` to enable it.

```yaml
MyCheckName:
  enabled: true
```

Add a corresponding test file under `test/checks`.

When done, run the tests with `dev test`.
