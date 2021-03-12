# Prevent JavaScript Abuse on Server Rendered Themes (`AssetSizeJavaScript`)

For server rendered pages, it is an anti-pattern to execute large JavaScript bundles on every navigation.

This doesn't mean they don't have a reason to exist. For instance, chat widgets are mini applications embedded inside web pages. Designing such an app with server rendered updates would be absurd. However, if only 10% of the users interact with the chat widget, the other 90% should not have to execute the entire bundle on every page load.

The natural solution to this problem is to implement the chat widget using the [Import on Interaction Pattern][ioip].

## Check Details

This rule disallows the use of theme JavaScript files and external scripts to have a compressed size greater than a configured `threshold_in_bytes`.

:-1: Examples of **incorrect** code for this check:
```liquid
<!-- Here assets/chat-widget.js is more than 10KB gzipped. -->
<script src="{{ 'chat-widget.js' | asset_url }}" defer></script>

<!-- The use of jQuery is discouraged in themes -->
<script src="https://code.jquery.com/jquery-3.6.0.min.js" defer></script>
```

:+1: Example of **correct** code for this check:
```liquid
<script>
  const chatWidgetButton = document.getElementById('#chat-widget')

  chatWidgetButton.addEventListener('click', e => {
    e.preventDefault();
    import("{{ 'chat-widget.js' | asset_url }}")
      .then(module => module.default)
      .then(ChatWidget => ChatWidget.init())
      .catch(err => {
        console.error(err);
      });
  });
</script>
```

## Check Options

The default configuration is the following.

```yaml
AssetSizeJavaScript:
  enabled: false
  threshold_in_bytes: 10000
```

### `threshold_in_bytes`

The `threshold_in_bytes` option (default: `10000`) determines the maximum allowed compressed size in bytes that a single JavaScript file can take.

This includes theme and remote scripts.

## When Not To Use It

When you can't do anything about it, it is preferable to disable this rule using the comment syntax:

```
{% comment %}theme-check-disable AssetSizeJavaScript{% endcomment %}
<script src="https://code.jquery.com/jquery-3.6.0.min.js" defer></script>
{% comment %}theme-check-enable AssetSizeJavaScript{% endcomment %}
```

This makes disabling the rule an explicit affair and shows that the code is smelly.

## Version

This check has been introduced in Theme Check 0.5.0.

## Resources

- [The Import On Interaction Pattern][ioip]
- [Rule Source][codesource]
- [Documentation Source][docsource]

[ioip]: https://addyosmani.com/blog/import-on-interaction/
[codesource]: /lib/theme_check/checks/asset_size_javascript.rb
[docsource]: /docs/checks/asset_size_javascript.md
