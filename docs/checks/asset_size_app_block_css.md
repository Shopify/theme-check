# Prevent Large CSS bundles (`AssetSizeAppBlockCSS`)

This rule exists to prevent large CSS bundles from being included via Theme App Extensions (for speed).

## Check Details

This rule disallows the use of too much CSS in themes, as configured by `threshold_in_bytes`.

:-1: Examples of **incorrect** code for this check:
```liquid
<!-- Here, assets/app.css is **greater** than `threshold_in_bytes` compressed. -->
{% schema %}
{
  ...
  "stylesheet": "app.css"
}
{% endschema %}
```

## Check Options

The default configuration is the following:

```yaml
AssetSizeAppBlockCSS:
  enabled: false
  threshold_in_bytes: 100_000
```

### `threshold_in_bytes`

The `threshold_in_bytes` option (default: `100_000`) determines the maximum allowed compressed size in bytes that a single CSS file can take.

This includes theme and remote stylesheets.

## When Not To Use It

This rule should not be disabled locally since the check will be enforced when
promoting new versions of the extension.

## Version

This check has been introduced in 1.1.0

## Resources

- [The Performance Inequality Gap](https://infrequently.org/2021/03/the-performance-inequality-gap/)
- [Rule Source][codesource]
- [Documentation Source][docsource]

[codesource]: /lib/theme_check/checks/asset_size_app_block_css.rb
[docsource]: /docs/checks/asset_size_app_block_css.md
