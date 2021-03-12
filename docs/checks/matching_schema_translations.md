# Spot errors in schema translations (`MatchingSchemaTranslations`)

Validates translations in schema tags (`{% schema %}`).

## Check Details

Add checks for eliminating translations mistakes in schema tags.

:-1: Examples of **incorrect** code for this check:

```liquid
{% comment %}
  - fr.missing is missing
  - fr.extra is not in the default locale
{% endcomment %}
{% schema %}
  {
    "locales": {
      "en": {
        "title": "Welcome",
        "missing": "Product"
      },
      "fr": {
        "title": "Bienvenue",
        "extra": "Extra"
      }
    }
  }
{% endschema %}

{% comment %}
  - The French product label is missing.
{% endcomment %}
{% schema %}
  {
    "name": {
      "en": "Hello",
      "fr": "Bonjour"
    },
    "settings": [
      {
        "id": "product",
        "label": {
          "en": "Product"
        }
      }
    ]
  }
{% endschema %}
```

:+1: Examples of **correct** code for this check:

```liquid
{% schema %}
  {
    "name": {
      "en": "Hello",
      "fr": "Bonjour"
    },
    "settings": [
      {
        "id": "product",
        "label": {
          "en": "Product",
          "fr": "Produit"
        }
      }
    ]
  }
{% endschema %}
```

## Check Options

The default configuration for this check is the following:

```yaml
MatchingSchemaTranslations:
  enabled: true
```

## Version

This check has been introduced in Theme Check 0.1.0.

## Resources

- [Rule Source][codesource]
- [Documentation Source][docsource]

[codesource]: /lib/theme_check/checks/matching_schema_translations.rb
[docsource]: /docs/checks/matching_schema_translations.md
