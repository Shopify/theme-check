# Encourage use of liquid tag for consecutive statements (LiquidTag)

Recommends using `{% liquid ... %}` if 4 or more consecutive liquid tags (`{% ... %}`) are found.

## Check Details

This check is aimed at eliminating repetitive tag markers (`{%` and `%}`) in theme files.

:-1: Example of **incorrect** code for this check:

```liquid
{% if collection.image.size != 0 %}
{%   assign collection_image = collection.image %}
{% elsif collection.products.first.size != 0 and collection.products.first.media != empty %}
{%   assign collection_image = collection.products.first.featured_media.preview_image %}
{% else %}
{%   assign collection_image = nil %}
{% endif %}
```

:+1: Example of **correct** code for this check:

```liquid
{%- liquid
  if collection.image.size != 0
    assign collection_image = collection.image
  elsif collection.products.first.size != 0 and collection.products.first.media != empty
    assign collection_image = collection.products.first.featured_media.preview_image
  else
    assign collection_image = nil
  endif
-%}
```

## Check Options

The default configuration for this check is the following:

```yaml
LiquidTag:
  enabled: true
  min_consecutive_statements: 5
```

### `min_consecutive_statements`

The `min_consecutive_statements` option (Default: `5`) determines the maximum (inclusive) number of consecutive statements before the check recommends a refactor.

## When Not To Use It

It's safe to disable this rule.

## Version

This check has been introduced in Theme Check 0.1.0.

## Resources

- [`{% liquid %}` Tag Reference][liquid]
- [Rule Source][codesource]
- [Documentation Source][docsource]

[liquid]: https://shopify.dev/docs/themes/liquid/reference/tags/theme-tags#liquid
[codesource]: /lib/theme_check/checks/liquid_tag.rb
[docsource]: /docs/checks/liquid_tag.md
