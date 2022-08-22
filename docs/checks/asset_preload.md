# Prevent Manual Preloading of Assets (`AssetPreload`)

_Version 1.11.0+_

Preloading can be a useful way of making sure that critical assets are downloaded by the browser as soon as possible for better rendering performance.

Liquid provides multiple filters to [preload key resources][preload_key_resources] so they can be converted into `Link` headers automatically. This enables them to be discovered even faster, especially when combined with Early Hints that Shopify supports.

## Examples

The following examples contain code snippets that either fail or pass this check.

### &#x2717; Fail

```liquid
<link href="{{ 'script.js' | asset_url }}" rel="preload" as="script">
<link href="{{ 'style.css' | asset_url }}" rel="preload" as="style">
<link href="{{ 'image.png' | asset_url }}" rel="preload" as="image">
```

### &#x2713; Pass

```liquid
{{ 'script.js' | asset_url | preload_tag: as: 'script' }}
{{ 'style.css' | asset_url | stylesheet_tag: preload: true }}
{{ 
  product.featured_image 
    | image_url: width: 600 
    | image_tag: preload: true 
}}
```

## Options

The following example contains the default configuration for this check:

```yaml
AssetPreload:
  enabled: true
  severity: suggestion
```

| Parameter | Description |
| --- | --- |
| enabled | Whether the check is enabled. |
| severity | The [severity](https://shopify.dev/themes/tools/theme-check/configuration#check-severity) of the check. |

## Disabling this check

It's safe to disable this rule. You may want to do it when trying to preload assets from external domain and it is not possible
to move them to Shopify because they change frequently or are dynamically generated.

## Resources

- [Rule source][codesource]
- [Documentation source][docsource]

[codesource]: /lib/theme_check/checks/asset_preload.rb
[docsource]: /docs/checks/asset_preload.md
[preload_key_resources]: https://shopify.dev/themes/best-practices/performance#use-resource-hints-to-preload-key-resources
