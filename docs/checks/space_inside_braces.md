# Ensure consistent spacing inside Liquid tags and variables (`SpaceInsideBraces`)

Warns against inconsistent spacing inside liquid tags and variables.

## Check Details

This check is aimed at eliminating ugly Liquid:

:-1: Examples of **incorrect** code for this check:

```liquid
<!-- Around braces -->
{% assign x = 1%}
{{ x}}
{{x }}

<!-- After commas and semicolons -->
{% form 'type',  object, key:value %}
{% endform %}
```

:+1: Examples of **correct** code for this check:

```liquid
{% assign x = 1 %}
{{ x }}
{% form 'type', object, key: value, key2: value %}
{% endform %}
{{ "ignore:stuff,  indeed" }}
{% render 'product-card',
  product_card_product: product_recommendation,
  show_vendor: section.settings.show_vendor,
  media_size: section.settings.product_recommendations_image_ratio,
  center_align_text: section.settings.center_align_text
%}
```

## Check Options

The default configuration for this check is the following:

```yaml
SpaceInsideBraces:
  enabled: true
```

## When Not To Use It

If you don't care about the look of your code.

## Version

This check has been introduced in Theme Check 0.1.0.

## Resources

- [Liquid Style Guide][styleguide]
- [Rule Source][codesource]
- [Documentation Source][docsource]

[styleguide]: https://github.com/Shopify/liquid-style-guide
[codesource]: /lib/theme_check/checks/space_inside_braces.rb
[docsource]: /docs/checks/space_inside_braces.md
