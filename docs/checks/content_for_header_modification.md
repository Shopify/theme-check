# Do not depend on the content of `content_for_header` (`ContentForHeaderModification`)

Do not rely on the content of `content_for_header` as it might change in the future, which could cause your Liquid code behavior to change.

## Check Details

:-1: Examples of **incorrect** code for this check:

```liquid
{% assign parts = content_for_header | split: ',' %}
```

:+1: Examples of **correct** code for this check:

The only acceptable usage of `content_for_header` is:

```liquid
{{ content_for_header }}
```

## Check Options

The default configuration for this check is the following:

```yaml
ContentForHeaderModification:
  enabled: true
```

## Version

This check has been introduced in Theme Check 0.9.0.

## Resources

- [Rule Source][codesource]
- [Documentation Source][docsource]
- [`theme.liquid` template considerations][considerations]

[codesource]: /lib/theme_check/checks/check_class_name.rb
[docsource]: /docs/checks/check_class_name.md
[considerations]: https://shopify.dev/docs/themes/theme-templates/theme-liquid#template-considerations
