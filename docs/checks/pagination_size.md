# Ensure `paginate` tags are used with performant sizes

## Check Details

This check is aimed at keeping response times low.

:-1: Examples of **incorrect** code for this check:

```liquid
<!-- Using too large of page size -->
{% paginate collection.products by 999 %}
```

:+1: Examples of **correct** code for this check:

```liquid
{% paginate collection.products by 12 %}
```

Use sizes that are integers below the `max_size`, and above the `min_size`.

## Check Options

The default configuration for this check is the following:

```yaml
PaginationSize:
  enabled: true
  ignore: []
  min_size: 1
  max_size: 50
```

## When Not To Use It

N/A

## Version

This check has been introduced in Theme Check 1.3.0.

## Resources

[paginate]: https://shopify.dev/api/liquid/objects/paginate
