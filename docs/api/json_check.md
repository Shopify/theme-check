# JSON check API

For checking the content of `.json` files.

```ruby
module ThemeCheck
  class MyCheckName < JsonCheck
    category :json,
    # A check can belong to multiple categories. Valid ones:
    categories :translation, :performance
    severity :suggestion # :error or :style

    def on_file(file)
      file # an instance of `ThemeCheck::JsonFile`
      file.content # the parsed JSON, as a Ruby object, usually a Hash
    end
  end
end
```
