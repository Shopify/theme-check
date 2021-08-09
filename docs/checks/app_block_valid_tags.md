# Reject Invalid Tags for Theme App Extension Blocks (`AppBlockValidTags`)

This rule exists to prevent invalid tags from being used in theme app extension blocks which will be rejected when the theme app extension is promoted.

## Check Details

This rule verifies no invalid tags are used for theme app extension app blocks. Invalid tags include:

- `{% javascript %}`
- `{% stylesheet %}`
- `{% include 'foo' %}`
- `{% layout 'foo' %}`
- `{% section 'foo' %}`

:-1: **Incorrect** code for this check occurs with the use of any of the above tags in theme app extension blocks.

## Check Options

The default configuration for theme app extensions is the following:

```yaml
AppBlockValidTags:
  enabled: true
```

## When Not To Use It

This rule should not be disabled locally since the check will be enforced when
promoting new versions of the extension.

## Version

This check has been introduced in THEME_CHECK_VERSION

## Resources

- [Rule Source][codesource]
- [Documentation Source][docsource]

[codesource]: /lib/theme_check/checks/app_block_valid_tags.rb
[docsource]: /docs/checks/app_block_valid_tags.md
