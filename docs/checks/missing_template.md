# Prevent missing templates (`MissingTemplate`)

This check exists to prevent rendering resources with the `render` tag, `section` tag (and the deprecated `include` tag) that do not exist.

## Check Details

This check is aimed at preventing liquid rendering errors.

:-1: Example of **incorrect** code for this check:

```liquid
{% render 'snippet-that-does-not-exist' %}
```

:+1: Example of **correct** code for this check:

```liquid
{% render 'article-card' %}
```

## Check Options

The default configuration for this check is the following:

```yaml
MissingTemplate:
  enabled: true
  ignore_missing: []
```

### `ignore_missing`

Specify a list of patterns of missing template files to ignore.

While the `ignore` option will ignore all occurrences of `MissingTemplate` according to the file in which they appear, `ignore_missing` allows ignoring all occurrences of `MissingTemplate` based on the target template, the template being rendered.

For example:

```yaml
MissingTemplate:
  ignore_missing:
  - snippets/icon-*
```

Would ignore offenses on `{% render 'icon-missing' %}` across all theme files.

```yaml
MissingTemplate:
  ignore:
  - templates/index.liquid
```

Would ignore all `MissingTemplate` in `templates/index.liquid`, no mater the file being rendered.

## Version

This check has been introduced in Theme Check 0.1.0.

## Resources

- [Rule Source][codesource]
- [Documentation Source][docsource]

[codesource]: /lib/theme_check/checks/missing_template.rb
[docsource]: /docs/checks/missing_template.md
