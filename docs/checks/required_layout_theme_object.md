# Prevent missing required objects in theme.liquid (`RequiredLayoutThemeObject`)

## Check Details

This check prevents missing `{{ content_for_header }}` and `{{ content_for_layout }}` objects in `layout/theme.liquid`.

## Check Options

The default configuration for this check is the following:

```yaml
RequiredLayoutThemeObject:
  enabled: true
```

## Version

This check has been introduced in Theme Check 0.1.0.

## Resources

- [Shopify theme.liquid requirements][themeliquid]
- [Rule Source][codesource]
- [Documentation Source][docsource]

[codesource]: /lib/theme_check/checks/required_layout_theme_object.rb
[docsource]: /docs/checks/required_layout_theme_object.md
[themeliquid]: https://shopify.dev/docs/themes/theme-templates/theme-liquid
