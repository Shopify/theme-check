# Enforce valid JSON (`ValidJson`)

This check exists to prevent invalid JSON files in themes.

## Check Details

This check is aimed at eliminating errors in JSON files.

:-1: Examples of **incorrect** code for this check:

```json
{
  "comma": "trailing",
}
```

```json
{
  "quotes": 'Oops, those are single quotes'
}
```

:+1: Examples of **correct** code for this check:

```json
{
  "comma": "not trailing"
}
```

```json
{
  "quotes": "Yes. Double quotes."
}
```

## Check Options

The default configuration for this check is the following:

```yaml
ValidJson:
  enabled: true
```

## When Not To Use It

It is not safe to disable this rule.

## Version

This check has been introduced in Theme Check 0.1.0.

## Resources

- [Rule Source][codesource]
- [Documentation Source][docsource]

[codesource]: /lib/theme_check/checks/valid_json.rb
[docsource]: /docs/checks/valid_json.md
