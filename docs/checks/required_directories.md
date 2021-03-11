# Prevent missing directories (`RequiredDirectories`)

This check exists to warn theme developers about missing required directories in their structure.

## Check Options

The default configuration for this check is the following:

```yaml
RequiredDirectories:
  enabled: true
```

## Version

This check has been introduced in Theme Check 0.1.0.

## Resources

- [Shopify Theme File Structure](https://shopify.dev/tutorials/develop-theme-files)
- [Rule Source][codesource]
- [Documentation Source][docsource]

[codesource]: /lib/theme_check/checks/required_directories.rb
[docsource]: /docs/checks/required_directories.md
