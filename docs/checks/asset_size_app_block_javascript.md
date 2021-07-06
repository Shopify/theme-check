# Prevent Abuse on Server Rendered App Blocks (`AssetSizeAppBlockJavaScript`)

For server rendered app blocks, it is an anti-pattern to execute large JavaScript bundles on every page load

This doesn't mean they don't have a reason to exist. For instance, chat widgets are mini applications embedded inside web pages. Designing such an app with server rendered updates would be absurd. However, if only 10% of the users interact with the chat widget, the other 90% should not have to execute the entire bundle on every page load.

The natural solution to this problem is to implement the chat widget using the [Import on Interaction Pattern][ioip].

## Check Details

This rule disallows the use of block JavaScript files and external scripts to have a compressed size greater than a configured `threshold_in_bytes`.

:-1: Examples of **incorrect** code for this check:
```liquid
<!-- Here assets/chat-widget.js is more than 10KB gzipped. -->
{% schema %}
{
  ...
  "javascript": "chat-widget.js"
}
{% endschema %}
```

## Check Options

The default configuration is the following:

```yaml
AssetSizeAppBlockJavaScript:
  enabled: true
  threshold_in_bytes: 10000
```

### `threshold_in_bytes`

The `threshold_in_bytes` option (default: `10000`) determines the maximum allowed compressed size in bytes that a single JavaScript file can take.

This includes theme and remote scripts.

## When Not To Use It

This rule should not be disabled locally since the check will be enforced when
promoting new versions of the extension.

## Version

This check has been introduced in 1.1.0

## Resources

- [The Import On Interaction Pattern][ioip]
- [Rule Source][codesource]
- [Documentation Source][docsource]

[ioip]: https://addyosmani.com/blog/import-on-interaction/
[codesource]: /lib/theme_check/checks/asset_size_app_block_javascript.rb
[docsource]: /docs/checks/asset_size_app_block_javascript.md
