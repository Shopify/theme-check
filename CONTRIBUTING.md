# Contributing to Theme Check

We love receiving pull requests!

For your contribution to be accepted you will need to sign the [Shopify Contributor License Agreement (CLA)](https://cla.shopify.com/).

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

```
bundle install # Or `dev up` if you're from Shopify
bundle exec rake
```

## Checking a theme

```
bundle exec theme-check /path/to/your/theme
```

## Creating a new "Check"

Run `bundle exec rake "new_check[MyNewCheckName]"` to generate all the files requires to create a new check.

Add the new check to `config/default.yml` to enable it. If the check is configurable, the `initialize` argument name and default values should also be duplicated inside `config/default.yml`.

```yaml
MyNewCheckName:
  enabled: true
  ignore: []
```

Check the [Check API](/docs/api/check.md) for details.