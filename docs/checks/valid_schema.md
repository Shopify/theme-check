# Enforce valid JSON in schema tags (`ValidSchema`)

This check exists to prevent invalid JSON in `{% schema %}` tags.

## Check Details

This check is aimed at eliminating JSON errors in schema tags.

:-1: Examples of **incorrect** code for this check:

```liquid
{% schema %}
{
  "comma": "trailing",
}
{% endschema %}
```

:+1: Examples of **correct** code for this check:

```liquid
{
  "comma": "not trailing"
}
```

## Check Options

The default configuration for this check is the following:

```yaml
ValidSchema:
  enabled: true
```

## When Not To Use It

It is not safe to disable this check.

## Version

This check has been introduced in Theme Check 0.1.0.

## Resources

- [Rule Source][codesource]
- [Documentation Source][docsource]

[codesource]: /lib/theme_check/checks/valid_schema.rb
[docsource]: /docs/checks/valid_schema.md
