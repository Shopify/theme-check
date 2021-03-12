# Prevent invalid HTML inside translations (`ValidHTMLTranslation`)

This check exists to prevent invalid HTML inside translations.

## Check Details

This check is aimed at eliminating invalid HTML in translations.

:-1: Examples of **incorrect** code for this check:

```liquid
{
  "hello_html": "<h2>Hello, world</h1>",
  "image_html": "<a href='/spongebob'>Unclosed"
}
```

:+1: Examples of **correct** code for this check:

```liquid
{% comment %}locales/en.default.json{% endcomment %}
{
  "hello_html": "<h1>Hello, world</h1>",
  "image_html": "<img src='spongebob.png'>",
  "line_break_html": "<br>",
  "self_closing_svg_html": "<svg />"
}
```

## Check Options

The default configuration for this check is the following:

```yaml
ValidHTMLTranslation:
  enabled: true
```

## When Not To Use It

It is discouraged to to disable this rule.

## Version

This check has been introduced in Theme Check 0.1.0.

## Resources

- [Rule Source][codesource]
- [Documentation Source][docsource]

[codesource]: /lib/theme_check/checks/valid_html_translation.rb
[docsource]: /docs/checks/valid_html_translation.md
