# Prevent unformatted schema tags (`SchemaJsonFormat`)

_Version 1.9.0+_

This check exists to ensure the JSON in your schemas is pretty.

It exists as a facilitator for its auto-correction. This way you can right-click fix the problem.

## Examples

The following examples contain code snippets that either fail or pass this check.

### &#x2717; Fail

```liquid
{% schema %}
{
  "locales": {
"en": {
  "title": "Welcome", "product": "Product"
},
          "fr": { "title": "Bienvenue", "product": "Produit" }
  }
}
{% endschema %}
```

### &#x2713; Pass

```liquid
{% schema %}
{
  "locales": {
    "en": {
      "title": "Welcome",
      "product": "Product"
    },
    "fr": {
      "title": "Bienvenue",
      "product": "Produit"
    }
  }
}
{% endschema %}
```

## Options

The following example contains the default configuration for this check:

```yaml
SchemaJsonFormat:
  enabled: true
  severity: style
  start_level: 0
  indent: '  '
```

| Parameter | Description |
| --- | --- |
| enabled | Whether the check is enabled. |
| severity | The [severity](https://shopify.dev/themes/tools/theme-check/configuration#check-severity) of the check. |
| start_level | The indentation level. If you prefer an indented schema, set this to 1. |
| indent | The character(s) used for indentation levels. |

## Disabling this check

 This check is safe to disable. You might want to disable this check if you do not care about the visual appearance of your schema tags.

## Resources

- [Rule source][codesource]
- [Documentation source][docsource]

[codesource]: /lib/theme_check/checks/schema_json_format.rb
[docsource]: /docs/checks/schema_json_format.md
