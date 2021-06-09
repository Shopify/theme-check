# HTML check API

For checking HTML elements in `.liquid` files.

If you need to check an HTML tag or its attributes, use an `HtmlCheck`.

The HTML in Liquid files is parsed using the Nokogiri, by consequence you will get [`Nokogiri::XML::Node`][nokogiri].


```ruby
module ThemeCheck
  class MyCheckName < HtmlCheck
    category :html,
    # A check can belong to multiple categories. Valid ones:
    categories :translation, :performance
    severity :suggestion # :error or :style

    def on_document(node)
      # Called with the root node of all templates
      node.value    # is an instance of Nokogiri::XML::Node
      node.template # is the template being analyzed, See lib/theme_check/template.rb.
      node.parent   # is the parent node.
      node.children # are the children nodes.
      # See lib/theme_check/html_node.rb for more helper methods
      theme # Gives you access to all the templates in the theme. See lib/theme_check/theme.rb.
    end

    def on_img(node)
      # Called for every <img> element in the file.
      node.attrbutes["class"] # Get the class attribute of the img element.
    end

    def on_a(node)
      # Called for every <a> element in the file.
    end
  end
end
```

## Resources

- [Nokogiri::XML::Node API doc][nokogiri]

[nokogiri]: https://www.rubydoc.info/github/sparklemotion/nokogiri/Nokogiri/XML/Node


