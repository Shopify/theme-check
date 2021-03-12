# Prevent undefined object errors (`UndefinedObject`)

This check prevents errors by making sure that no undefined variables are being used

## Check Details

This check is aimed at eliminating undefined object errors.

:-1: Examples of **incorrect** code for this check:

```liquid
{% assign greetings = "Hello" %}
{% if greeting == "Hello" %}

{{ articl }}
{{ prodcut }}
```

:+1: Examples of **correct** code for this check:

```liquid
{% assign greetings = "Hello" %}
{% if greetings == "Hello" %}

{{ article }}
{{ product }}
```

## Check Options

The default configuration for this check is the following:

```yaml
UndefinedObject:
  enabled: true
```

## When Not To Use It

It is discouraged to disable this rule.

## Version

This check has been introduced in Theme Check 0.1.0.

## Resources

- [Shopify Object Reference](https://shopify.dev/docs/themes/liquid/reference/objects)
- [Rule Source][codesource]
- [Documentation Source][docsource]

[codesource]: /lib/theme_check/checks/undefined_object.rb
[docsource]: /docs/checks/undefined_object.md
