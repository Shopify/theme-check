# Theme Check ✅ - A linter for Themes

Think RuboCop, or eslint, but for Shopify themes.

Theme Check is a command line tool that helps you follow Shopify Themes & Liquid best practices by analyzing the Liquid & JSON inside your theme.

Theme Check is also available [inside some code editors](https://github.com/Shopify/theme-check/wiki).

![](docs/preview.png)

_Disclaimer: This tool is not supported as part of the Partners program._

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
✅ Undefined [objects](https://shopify.dev/docs/themes/liquid/reference/objects)
✅ Deprecated filters  

And many more to come! Suggestions welcome ([create an issue](https://github.com/Shopify/theme-check/issues)).

## Requirements

- Ruby 2.7+

## Installation

Theme Check is available through Homebrew _or_ RubyGems.

**Homebrew**

You’ll need to run `brew tap` first to add Shopify’s third-party repositories to Homebrew.

```sh
brew tap shopify/shopify
brew install theme-check
```

**RubyGems**

```sh
gem install theme-check
```

## Usage

```
theme-check /path/to/your/theme

# or from /path/to/your/theme
theme-check
```

Run `theme-check --help` to get full usage.

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
