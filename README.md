# Theme Check ✅ - A linter for Themes

_This is a [HackDays project](https://hackdays.shopify.io/projects/13720)_

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
