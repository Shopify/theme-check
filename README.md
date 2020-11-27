# Theme Check ✅ - A linter for Themes

_This is a [HackDays project](https://hackdays.shopify.io/projects/13720)_

Theme Check is a command line tool that helps you follow Shopify Themes & Liquid best practices by analyzing the Liquid code inside the templates of your theme.

Think RuboCop, or eslint, but for Liquid, and designed specifically to be used on themes.

![](docs/preview.png)

## Usage

```
dev up
dev check /path/to/your/theme
```

## Supported Checks

Theme Check currently checks for the following:

✅ Liquid parsing errors  
✅ Unused `{% assign ... %}`  
✅ Unused `snippets/` templates  
✅ Template length is under 200 lines  
✅ Use of `{% liquid ... %}` instead of several `{% ... %}`
✅ Deprecated tags: `include`
✅ Nesting too many snippets

And many more to come! Suggestions welcome (create an issue).

## Creating a new "Check"

Under `lib/theme_check/checks`, create new Ruby file with a unique name describing what you want to check for.

```ruby
module ThemeCheck
  # Does one thing, and does it well!
  class MyCheckName < Check
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

    def on_tag(node)
      # Called for each tag (if, include, for, assign, etc.)
    end

    def after_tag(node)
      # Called after the tag children have been visited
      
      # If you find an issue, add an offense:
      add_offense("Describe the problem...", node: node)
    end

    def on_assign(node)
      # Called only for {% assign ... %} tags
    end

    def on_error(exception)
      # Called each time a Liquid exception is raised while parsing the template
    end

    def on_end
      # A special callback after we're done visiting all the templates
    end

    # Each type of node has a corresponding `on_node_class_name` & `after_node_class_name`
    # A few common examples:
    # on_if(node)
    # on_include(node)
    # on_render(node)
    # on_condition(node)
    # on_variable(node)
    # on_variable_lookup(node)
    # on_string(node)
    # on_block_body(node)
    # on_form(node)
    # on_section(node)
    # on_style(node)
    # on_schema(node)
    # ...
  end
end
```

Add a corresponding test file under `test/checks`.

When done, run the tests with `dev test`.
