# HTML check API

For checking HTML elements in `.liquid` files.

If you need to check an HTML tag or its attributes, use an `HtmlCheck`.

The HTML in Liquid files is parsed using the Nokogiri, by consequence you will get [`Nokogiri::XML::Node`][nokogiri].


```ruby
module PlatformosCheck
  class MyCheckName < HtmlCheck
    category :html,
    # A check can belong to multiple categories. Valid ones:
    categories :translation, :performance
    severity :suggestion # :error or :style

    def on_document(node)
      # Called with the root node of all theme files
      node.value      # is an instance of Nokogiri::XML::Node
      node.theme_file # is the html_file being analyzed, See lib/platformos_check/theme_file.rb.
      node.parent     # is the parent node.
      node.children   # are the children nodes.
      # See lib/platformos_check/html_node.rb for more helper methods
      theme # Gives you access to all the theme files in the theme. See lib/platformos_check/theme.rb.
    end

    def on_img(node)
      # Called for every <img> element in the file.
      node.attributes["class"] # Get the class attribute of the img element.
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


