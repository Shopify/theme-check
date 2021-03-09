# Prevent JavaScript Abuse on Server Rendered Themes (AssetSizeJavaScript)

For server rendered pages, it is an anti-pattern to execute large JavaScript bundles on every navigation.

This doesn't mean they don't have a reason to exist. For instance, chat widgets are mini applications embedded inside web pages. Designing such an app with server rendered updates would be absurd. However, if only 10% of the users interact with the chat widget, the other 90% should not have to execute the entire bundle on every page load.

The natural solution to this problem is to implement the chat widget using the [Import on Interaction Pattern][ioip].

## Rule Details

This rule disallows the use of theme JavaScript files and external scripts to have a compressed size greater than a configured `threshold_in_bytes`.

**:-1: Example of incorrect code for this rule:**
```liquid
<!-- Here assets/chat-widget.js is more than 10KB gzipped. -->
<script src="{{ 'chat-widget.js' | asset_url }}" defer></script>

<!-- The use of jQuery is discouraged in themes -->
<script src="https://code.jquery.com/jquery-3.6.0.min.js" defer></script>
```

**:+1: Example of correct code for this rule:**
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

## Configuration

The default configuration is the following.

```yaml
AssetSizeJavaScript:
  enabled: true
  threshold_in_bytes: 10000
```

Options:

- `enabled`: (Default: `true`) whether the check is enabled or not. (Default: true)
- `threshold_in_bytes`: (Default: `10000`)

## Resources

- [The Impact On Interaction Pattern][ioip]
- [Rule Source][source]
- [Documentation Source][doc]

[ioip]: https://addyosmani.com/blog/import-on-interaction/
[source]: https://github.com/Shopify/theme-check/blob/master/lib/theme_check/checks/asset_size_javascript.rb
[doc]: https://github.com/Shopify/theme-check/blob/master/docs/checks/asset_size_javascript.md
