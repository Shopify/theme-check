# Prevent missing theme-check-enable comments (`MissingEnableComment`)

When `theme-check-disable` is used in the middle of a template, the corresponding `theme-check-enable` comment should also be included.

## Check Details

This check aims at eliminating missing `theme-check-enable` comments.

:-1: Example of **incorrect** code for this check:

```liquid
<!doctype html>
<html>
  <head>
    {% comment %}theme-check-disable ParserBlockingJavaScript{% endcomment %}
    <script src="https://cdnjs.com/jquery.min.js"></script>
  </head>
  <body>
    <!-- ... -->
  </body>
</html>
```

:+1: Example of **correct** code for this check:

```liquid
<!doctype html>
<html>
  <head>
    {% comment %}theme-check-disable ParserBlockingJavaScript{% endcomment %}
    <script src="https://cdnjs.com/jquery.min.js"></script>
    {% comment %}theme-check-enable ParserBlockingJavaScript{% endcomment %}
  </head>
  <body>
    <!-- ... -->
  </body>
</html>
```

## Version

This check has been introduced in Theme Check 0.3.0.

## Resources

- [Rule Source][codesource]
- [Documentation Source][docsource]

[codesource]: /lib/theme_check/checks/missing_enable_comment.rb
[docsource]: /docs/checks/missing_enable_comment.md
