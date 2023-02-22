# Enforce snake_case for variable names (`VariableName`)

This check exists to enforce consistent naming of variables.

## Check Details

This checks requires variable names to be writen in `snake_case`.

## Examples

The following examples contain code snippets that either fail or pass this check.

### &#x2717; Fail

```liquid
{{ myVariable }}
{{ assign otherVariable = value }}
```

### &#x2713; Pass

```liquid
{{ my_variable }}
{{ assign other_variable = value}}
```


## Check Options

The default configuration for this check is the following:

```yaml
VariableName:
  enabled: true
```

## When Not To Use It

It's safe to disable this rule.

## Version

This check has been introduced in Theme Check 1.15.0.

## Resources

- [Rule source][codesource]
- [Documentation source][docsource]

[codesource]: /lib/theme_check/checks/variable_name.rb
[docsource]: /docs/checks/variable_name.md
