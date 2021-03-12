# Prevent use of undefined translations (`TranslationKeyExists`)

This check exists to prevent translation errors in themes.

## Check Details

This check is aimed at eliminating the use of translations that do not exist.

:-1: Examples of **incorrect** code for this check:

```liquid
{% comment %}locales/en.default.json{% endcomment %}
{
  "greetings": "Hello, world!",
  "general": {
    "close": "Close"
  }
}

{% comment %}templates/index.liquid{% endcomment %}
{{ "notfound" | t }}
```

:+1: Examples of **correct** code for this check:

```liquid
{% comment %}locales/en.default.json{% endcomment %}
{
  "greetings": "Hello, world!",
  "general": {
    "close": "Close"
  }
}

{% comment %}templates/index.liquid{% endcomment %}
{{ "greetings" | t }}
{{ "general.close" | t }}
```

## Check Options

The default configuration for this check is the following:

```yaml
TranslationKeyExists:
  enabled: true
```

## When Not To Use It

It is not safe to disable this check.

## Version

This check has been introduced in Theme Check 0.1.0.

## Resources

- [Rule Source][codesource]
- [Documentation Source][docsource]

[codesource]: /lib/theme_check/checks/translation_key_exists.rb
[docsource]: /docs/checks/translation_key_exists.md
