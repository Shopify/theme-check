# Ensure `asset_url` filters are used when serving assets (`AssetUrlFilters`)

See the [`RemoteAsset` check documentation][remote_asset] for a detailed explanation on why remote assets are discouraged.

## Check Details

This check is aimed at eliminating unnecessary HTTP connections.

:-1: Examples of **incorrect** code for this check:

```liquid
<!-- Using multiple CDNs -->
{{ "https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/css/bootstrap.min.css" | stylesheet_tag }}

<!-- Missing img_url filter -->
{{ url | img_tag }}
```

:+1: Examples of **correct** code for this check:

```liquid
{{ 'bootstrap.min.css' | asset_url | stylesheet_tag }}

<!-- Images -->
{{ url | img_url | img_tag }}
```

Use the [`assets_url`](asset_url) or [`img_url`](img_url) filter to load the files in your theme's `assets/` folder from the Shopify CDN.

## Check Options

The default configuration for this check is the following:

```yaml
AssetUrlFilters:
  enabled: true
```

## When Not To Use It

When the remote content is highly dynamic.

## Version

This check has been introduced in Theme Check 0.9.1.

## Resources

- [Rule Source][codesource]
- [Documentation Source][docsource]

[codesource]: /lib/theme_check/checks/remote_asset_filters.rb
[docsource]: /docs/checks/remote_asset_filters.md
[remote_asset]: /docs/checks/remote_asset.md
[asset_url]: https://shopify.dev/docs/themes/liquid/reference/filters/url-filters#assert_url
[img_url]: https://shopify.dev/docs/themes/liquid/reference/filters/url-filters#img_url
