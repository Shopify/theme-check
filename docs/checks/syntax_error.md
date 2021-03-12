# Prevent Syntax Errors (`SyntaxError`)

This check exists to inform the user of Liquid syntax error earlier.

## Check Details

This check is aimed at eliminating syntax errors.

:-1: Examples of **incorrect** code for this check:

```liquid
{% include 'muffin'
{% assign foo = 1 }}
{% unknown %}
{% if collection | size > 0 %}
```

:+1: Examples of **correct** code for this check:

```liquid
{% include 'muffin' %}
{% assign foo  = 1 %}
{% if collection.size > 0 %}
```

## Check Options

The default configuration for this check is the following:

```yaml
SyntaxError:
  enabled: true
```

## When Not To Use It

It is not safe to disable this rule.

## Version

This check has been introduced in Theme Check 0.1.0.

## Resources

- [Rule Source][codesource]
- [Documentation Source][docsource]

[codesource]: /lib/theme_check/checks/syntax_error.rb
[docsource]: /docs/checks/syntax_error.md
