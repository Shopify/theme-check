# Prevent use of unknown filters (`UnknownFilter`)

This check exists to prevent user errors.

## Check Details

This check is aimed at preventing the use of unknown filters.

:-1: Examples of **incorrect** code for this check:

```liquid
{{ x | some_unknown_filter }}
```

:+1: Examples of **correct** code for this check:

```liquid
{{ x | upcase }}
```

## Check Options

The default configuration for this check is the following:

```yaml
UnknownFilter:
  enabled: true
```

## When Not To Use It

It is not safe to disable this rule.

## Version

This check has been introduced in Theme Check 0.1.0.

## Resources

- [Shopify Filter Reference](https://shopify.dev/docs/themes/liquid/reference/filters)
- [Rule Source][codesource]
- [Documentation Source][docsource]

[codesource]: /lib/theme_check/checks/unknown_filter.rb
[docsource]: /docs/checks/unknown_filter.md
