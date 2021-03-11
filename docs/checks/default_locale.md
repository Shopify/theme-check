# Ensure theme has a default locale (`DefaultLocale`)

This check makes sure the theme has a default translation file.

## Check Details

This check makes sure a theme has a default locale.

:-1: Example of **incorrect** theme for this check:

```
locales/
├── en.json
├── fr.json
└── zh-TW.json
```

:+1: Example of **correct** theme for this check:

```
locales/
├── en.default.json  # a default translation file is required
├── fr.json
└── zh-TW.json
```

## Check Options

The default configuration for this check is the following:

```yaml
DefaultLocale:
  enabled: true
```

## Version

This check has been introduced in Theme Check 0.1.0.

## Resources

- [Rule Source][codesource]
- [Documentation Source][docsource]

[codesource]: /lib/theme_check/checks/default_locale.rb
[docsource]: /docs/checks/default_locale.md
