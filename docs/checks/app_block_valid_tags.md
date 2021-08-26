# Reject Forbidden Tags from Theme App Extension Blocks (`AppBlockValidTags`)

This rule exists to prevent theme app extension blocks from containing forbidden tags in their liquid code.

## Check Details

This rule verifies none of the below tags are used in theme app extension blocks.

- `{% javascript %}`
- `{% stylesheet %}`
- `{% include 'foo' %}`
- `{% layout 'foo' %}`
- `{% section 'foo' %}`

:-1: **Incorrect** code for this check occurs with the use of any of the above tags in the liquid code of theme app extension blocks.

## Check Options

The default configuration for theme app extensions is the following:

```yaml
AppBlockValidTags:
  enabled: true
```

## When Not To Use It

This rule should not be disabled locally.

## Version

This check has been introduced in 1.3.0

## Resources

- [Rule Source][codesource]
- [Documentation Source][docsource]

[codesource]: /lib/theme_check/checks/app_block_valid_tags.rb
[docsource]: /docs/checks/app_block_valid_tags.md
