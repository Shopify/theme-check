# Remove unused snippets in themes (`UnusedSnippet`)

This check warns the user about snippets that are not used (Could not find a `render` tag that uses that snippet)

## Check Details

This check is aimed at eliminating unused snippets.

## Check Options

The default configuration for this check is the following:

```yaml
UnusedSnippet:
  enabled: true
```

## When Not To Use It

It's safe to disable this rule.

## Version

This check has been introduced in Theme Check 0.1.0.

## Resources

- [Rule Source][codesource]
- [Documentation Source][docsource]

[codesource]: /lib/theme_check/checks/unused_snippet.rb
[docsource]: /docs/checks/unused_snippet.md
