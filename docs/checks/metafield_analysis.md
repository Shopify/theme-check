# Check Title (`MetafieldAnalysis`)

_Version THEME_CHECK_VERSION+_

A short description of what the check does.

A brief paragraph explaining why the check exists (what best practice is it enforcing, and why is it important?).

## Examples

The following examples contain code snippets that either fail or pass this check.

### &#x2717; Fail

```liquid
```

### &#x2713; Pass

```liquid
```

## Options

The following example contains the default configuration for this check:

```yaml
MetafieldAnalysis:
  enabled: false
  severity: suggestion
  other_option: 10_000
```

| Parameter | Description |
| --- | --- |
| enabled | Whether the check is enabled. |
| severity | The [severity](https://shopify.dev/themes/tools/theme-check/configuration#check-severity) of the check. |
| other_option | A description of the option. |

## Disabling this check

[ This check is safe to disable. You might want to disable this check if ... | Disabling this check isn't recommended because ... ].

[ This check is disabled by default when <condition>. ]

## Resources

- [Rule source][codesource]
- [Documentation source][docsource]

[codesource]: /lib/theme_check/checks/metafield_analysis.rb
[docsource]: /docs/checks/metafield_analysis.md
