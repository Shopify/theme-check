# Theme Check ✅ - A linter for Themes

_This is a [HackDays project](https://hackdays.shopify.io/projects/13720)_

Think RuboCop, or eslint, but for Shopify themes.

Theme Check is a command line tool that helps you follow Shopify Themes & Liquid best practices by analyzing the Liquid & JSON inside your theme.

Theme Check is also available [inside some code editors](https://github.com/Shopify/theme-check/wiki).

![](docs/preview.png)

## Supported Checks

Theme Check currently checks for the following:

✅ Liquid syntax errors  
✅ JSON syntax errors  
✅ Missing snippet & section templates  
✅ Unused `{% assign ... %}`  
✅ Unused snippet templates  
✅ Template length  
✅ Deprecated tags  
✅ Unknown tags  
✅ Unknown filters  
✅ Missing `{{ content_for_* }}` in `theme.liquid`  
✅ Excessive nesting of snippets  
✅ Missing or extra spaces inside `{% ... %}` and `{{ ... }}`  
✅ Missing default locale file  
✅ Unmatching translation keys in locale files  
✅ Using unknown translation keys in `{{ 'missing_key' | t }}`  
✅ Using several `{% ... %}` instead of `{% liquid ... %}`  

And many more to come! Suggestions welcome ([create an issue](https://github.com/Shopify/theme-check/issues)).

## Usage

```
dev clone theme-check
dev up
dev check /path/to/your/theme
```

## Configuration

Add a `.theme-check.yml` file at the root of your theme to configure:

```yaml
# If your theme is not using the supported directory structure, provide the root path
# where to find the `templates/`, `sections/`, `snippets/` directories as they would
# be uploaded to Shopify.
root: dist

# Disable some checks
TemplateLength:
  enabled: false
  # Or configure options
  max_length: 300
```

See [config/default.yml](config/default.yml) for available options & defaults.

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
