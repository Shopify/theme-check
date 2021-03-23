# Prevent Large CSS bundles (`AssetSizeCSS`)

This rule exists to prevent large CSS bundles (for speed).

## Check Details

This rule disallows the use of too much CSS in themes, as configured by `threshold_in_bytes`.

:-1: Examples of **incorrect** code for this check:
```liquid
<!-- Here, assets/theme.css is **greater** than `threshold_in_bytes` compressed. -->
{{ 'theme.css' | asset_url | stylesheet_tag }}
```

:+1: Example of **correct** code for this check:
```liquid
<!-- Here, assets/theme.css is **less** than `threshold_in_bytes` compressed. -->
{{ 'theme.css' | asset_url | stylesheet_tag }}
```

## Check Options

The default configuration is the following.

```yaml
AssetSizeCSS:
  enabled: false
  threshold_in_bytes: 100_000
```

### `threshold_in_bytes`

The `threshold_in_bytes` option (default: `100_000`) determines the maximum allowed compressed size in bytes that a single CSS file can take.

This includes theme and remote stylesheets.

## When Not To Use It

This rule is safe to disable.

## Version

This check has been introduced in Theme Check 0.6.0.

## Resources

- [The Performance Inequality Gap](https://infrequently.org/2021/03/the-performance-inequality-gap/)
- [Rule Source][codesource]
- [Documentation Source][docsource]

[codesource]: /lib/theme_check/checks/asset_size_css.rb
[docsource]: /docs/checks/asset_size_css.md
