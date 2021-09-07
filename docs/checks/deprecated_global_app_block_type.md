# Check for deprecated global app block type `@global`
This check makes sure theme sections are not using [deprecated (`@global`)][change_log] global app block type.

## Check Details
In order for theme sections to [support app blocks][support_app_blocks_in_theme_section], sections need to define a block of type `@app`. This check makes sure that theme sections are not using the deprecated (`@global`) global app block type in theme sections.

:-1: Example of **incorrect** theme section for this check:
```
{% for block in section.blocks %}
  {% if block.type = "@global" %}
    {% render block %}
  {% endif %}
{% endfor %}

{% schema %}
{
  "name": "Product section",
  "blocks": [{"type": "@global"}]
}
{% endschema %}
```

:+1: Examples of **correct** theme section for this check:
```
{% for block in section.blocks %}
  {% if block.type = "@app" %}
    {% render block %}
  {% endif %}
{% endfor %}

{% schema %}
{
  "name": "Product section",
  "blocks": [{"type": "@app"}]
}
{% endschema %}
```

## Check Options

The default configuration for this check is the following:

```yaml
DeprecatedGlobalAppBlockType:
  enabled: true
```

## When Not To Use It

It is discouraged to disable this check.

## Version

This check has been introduced in Theme Check 1.5.0.

## Resources

- [Rule Source][codesource]
- [Documentation Source][docsource]

[codesource]: /lib/theme_check/checks/deprecated_global_app_block_type.rb
[docsource]: /docs/checks/deprecated_global_app_block_type.md
[remote_asset]: /docs/checks/deprecated_global_app_block_type.md
[support_app_blocks_in_theme_section]: https://shopify.dev/themes/migration#step-8-add-support-for-app-blocks-to-sections
[change_log]: https://shopify.dev/changelog/removing-the-global-block-type-in-favour-of-the-app-block-type-in-theme-sections
