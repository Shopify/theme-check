# Limit the level of loop nesting (`NestedLoop`)

Checks that there is no excessive loop nesting. This ensures high-performant themes.

## Examples

The following examples contain code snippets that either fail or pass this check.

### &#x2717; Fail

```liquid
{% for product in collection.products %}
  {% for tag in product.tags %}
    {% for variant in product.variants %}

    {% endfor %}
  {% endfor %}
{% endfor %}
```

### &#x2713; Pass

```liquid
{% for product in collection.products %}
  {% for variant in product.variants %}

  {% endfor %}
{% endfor %}
```

## Options

The following example contains the default configuration for this check:

```yaml
NestedLoop:
  enabled: true
  severity: error
  max_nesting_level: 2
```

| Parameter | Description |
| --- | --- |
| enabled | Whether the check is enabled. |
| severity | The [severity](https://shopify.dev/themes/tools/theme-check/configuration#check-severity) of the check. |
| max_nesting_level | The maximum nesting before an error is reported. |

## Disabling this check

Disabling this check isn't recommended because nested loops can lead to poor performance. You can however configure higher number for `max_nesting_level`, if nesting is unavoidable.

## Version

 This check has been introduced in Theme Check 1.15.0.

## Resources

- [Rule source][codesource]
- [Documentation source][docsource]

[codesource]: /lib/theme_check/checks/nested_loop.rb
[docsource]: /docs/checks/nested_loop.md
