# Prevent deeply nested snippets (`NestedSnippet`)

Reports deeply nested `render` tags (or deprecated `include` tags).

## Check Details

This check is aimed at eliminating excessive nesting of snippets.

:-1: Examples of **incorrect** code for this check:

```liquid
{% comment %}templates/index.liquid{% endcomment %}
  {% render 'one' %}

{% comment %}snippets/one.liquid{% endcomment %}
  {% render 'two' %}

{% comment %}snippets/two.liquid{% endcomment %}
  {% render 'three' %}

{% comment %}snippets/three.liquid{% endcomment %}
  {% render 'four' %}

{% comment %}snippets/four.liquid{% endcomment %}
  ok
```

:+1: Examples of **correct** code for this check:

```liquid
{% comment %}templates/index.liquid{% endcomment %}
  {% render 'one' %}

{% comment %}snippets/one.liquid{% endcomment %}
  {% render 'two' %}

{% comment %}snippets/two.liquid{% endcomment %}
  ok
```

## Check Options

The default configuration for this check is the following:

```yaml
NestedSnippet:
  enabled: true
  max_nesting_level: 3
```

### `max_nesting_level`

The `max_nesting_level` option (Default: `2`) determines the maximum depth of snippets rendering snippets.

## When Not To Use It

It's safe to disable this rule.

## Version

This check has been introduced in Theme Check 0.1.0.

## Resources

- [Rule Source][codesource]
- [Documentation Source][docsource]

[codesource]: /lib/theme_check/checks/nested_snippet.rb
[docsource]: /docs/checks/nested_snippet.md
