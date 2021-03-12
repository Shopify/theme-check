# Prevent unused assigns (`UnusedAssign`)

This check exists to prevent bloat in themes by surfacing variable definitions that are not used.

## Check Details

This check is aimed at eliminating bloat in themes and highlight user errors.

:-1: Examples of **incorrect** code for this check:

```liquid
{% assign this_variable_is_not_used = 1 %}
```

:+1: Examples of **correct** code for this check:

```liquid
{% assign this_variable_is_used = 1 %}
{% if this_variable_is_used == 1 %}
  <span>Hello!</span>
{% endif %}
```

## Check Options

The default configuration for this check is the following:

```yaml
UnusedAssign:
  enabled: true
```

## When Not To Use It

It's safe to disable this rule.

## Version

This check has been introduced in Theme Check 0.1.0.

## Resources

- [Rule Source][codesource]
- [Documentation Source][docsource]

[codesource]: /lib/theme_check/checks/unused_assign.rb
[docsource]: /docs/checks/unused_assign.md
