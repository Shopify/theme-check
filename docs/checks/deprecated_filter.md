# Discourage use of deprecated filters (`DeprecatedFilter`)

This check discourages the use of [deprecated filters][deprecated].

## Check Details

This check is aimed at eliminating deprecated filters.

:-1: Example of **incorrect** code for this check:

```liquid
.site-footer p {
  color: {{ settings.color_name | hex_to_rgba: 0.5 }};
}
```

:+1: Example of **correct** code for this check:

```liquid
.site-footer p {
  color: {{ settings.color_name | color_modify: 'alpha', 0.5 }};
}
```

## Check Options

The default configuration for this check is the following:

```yaml
DeprecatedFilter:
  enabled: true
```

## Version

This check has been introduced in Theme Check 0.2.0.

## Resources

- [Deprecated Filters Reference][deprecated]
- [Rule Source][codesource]
- [Documentation Source][docsource]

[deprecated]: https://shopify.dev/docs/themes/liquid/reference/filters/deprecated-filters
[codesource]: /lib/theme_check/checks/deprecated_filter.rb
[docsource]: /docs/checks/deprecated_filter.md
