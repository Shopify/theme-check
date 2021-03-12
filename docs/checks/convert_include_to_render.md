# Discourage the use of `include` (`ConvertIncludeToRender`)

The `include` tag is [deprecated][deprecated]. This tag exists to enforce the use of the `render` tag instead of `include`.

The `include` tag works similarly to the `render` tag, but it lets the code inside of the snippet to access and overwrite the variables within its parent template. The `include` tag has been deprecated because the way that it handles variables reduces performance and makes theme code harder to both read and maintain.

## Check Details

This check is aimed at eliminating the use of `include` tags.

:-1: Examples of **incorrect** code for this check:

```liquid
{% include 'snippet' %}
```

:+1: Examples of **correct** code for this check:

```liquid
{% render 'snippet' %}
```

## Check Options

The default configuration for this check is the following:

```yaml
ConvertIncludeToRender:
  enabled: true
```

## When Not To Use It

It is discouraged to disable this rule.

## Version

This check has been introduced in Theme Check 0.1.0.

## Resources

- [Deprecated Tags Reference][deprecated]
- [Rule Source][codesource]
- [Documentation Source][docsource]

[deprecated]: https://shopify.dev/docs/themes/liquid/reference/tags/deprecated-tags#include
[codesource]: /lib/theme_check/checks/convert_include_to_render.rb
[docsource]: /docs/checks/convert_include_to_render.md
