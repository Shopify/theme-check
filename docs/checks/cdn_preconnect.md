# Check Title (`CdnPreconnect`)

_Version PLATFORMOS_CHECK_VERSION+_

The preconnect resource hint is a useful way of making sure connections to external domains are ready as soon as possible. It can improve performance by enabling the browser to start downloading critical assets right after discovering them in the HTML.

Because every Shopify store makes use of `cdn.shopify.com`, the platform already includes the preconnect resource hint inside the `Link` header in the main document response. This makes the preconnect in the HTML redundant.

With the rollout of [moving CDN assets to the main store domain](https://changelog.shopify.com/posts/changes-to-asset-urls), it becomes even more unnecessary as there may be no assets coming from `cdn.shopify.com`. In this case, the redundant preconnect can negatively impact performance.

## Examples

The following examples contain code snippets that either fail or pass this check.

### &#x2717; Fail

```liquid
<link href="https://cdn.shopify.com" rel="preconnect">
<link href="https://cdn.shopify.com" rel="preconnect" crossorigin>
```

### &#x2713; Pass

```liquid
<link href="https://example.com/" rel="preconnect">
<link href="https://example.com/" rel="preconnect" crossorigin>
```

## Options

The following example contains the default configuration for this check:

```yaml
CdnPreconnect:
  enabled: true
  severity: suggestion
```

| Parameter | Description |
| --- | --- |
| enabled | Whether the check is enabled. |
| severity | The [severity](https://shopify.dev/themes/tools/platformos-check/configuration#check-severity) of the check. |

## Disabling this check

Disabling this check isn't recommended because preconnect to Shopify's CDN is in the best case redundant and in the worst case negatively impacts performance.

## Resources

- [Introduction to resource hints][resourcehints]
- [Rule source][codesource]
- [Documentation source][docsource]

[resourcehints]: https://performance.shopify.com/blogs/blog/introduction-to-resource-hints
[codesource]: /lib/platformos_check/checks/cdn_preconnect.rb
[docsource]: /docs/checks/cdn_preconnect.md
