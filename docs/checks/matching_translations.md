# Prevent mismatching translations (`MatchingTranslations`)

This check exists to prevent missing and superfluous translations in locale files.

## Check Details

This check warns against missing translations in locale files.

:-1: Examples of **incorrect** code for this check:

```js
// en.default.json
{
  "greeting": "Hello, world",
  "goodbye": "Bye, world"
}

// fr.json - missing `greeting` and `goodbye`
{
}

// fr.json - missing `greeting` and superfluous `goodby`
{
  "greeting": "Bonjour, monde"
  "goodby": "Au revoir, monde"
}
```

:+1: Example of **correct** code for this check:

```liquid
// en.default.json
{
  "greeting": "Hello, world",
  "goodbye": "Bye, world"
  "pluralized_greeting": {
    "one": "Hello, you",
    "other": "Hello, y'all",
  }
}

// fr.json
{
  "greeting": "Bonjour, monde"
  "goodbye": "Au revoir, monde"
  "pluralized_greeting": {
    "zero": "Je suis seul :(",
    "few": "Salut, groupe!"
  }
}
```

## Check Options

The default configuration for this check is the following:

```yaml
MatchingTranslations:
  enabled: true
```

## Version

This check has been introduced in Theme Check 0.1.0.

## Resources

- [Rule Source][codesource]
- [Documentation Source][docsource]

[codesource]: /lib/theme_check/checks/matching_translations.rb
[docsource]: /docs/checks/matching_translations.md
