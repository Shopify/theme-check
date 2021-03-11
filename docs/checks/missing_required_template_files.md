# Prevent missing required theme files (`MissingRequiredTemplateFiles`)

Makes sure all the required template files in a theme are present.

## Check Options

The default configuration for this check is the following:

```yaml
MissingRequiredTemplateFiles:
  enabled: true
```

## Version

This check has been introduced in Theme Check 0.1.0.

## Resources

- [Theme Requirements](https://shopify.dev/tutorials/review-theme-store-requirements-files)
- [Theme Templates](https://shopify.dev/docs/themes/theme-templates)
- [Rule Source][codesource]
- [Documentation Source][docsource]

[codesource]: /lib/theme_check/checks/missing_required_template_files.rb
[docsource]: /docs/checks/missing_required_template_files.md
