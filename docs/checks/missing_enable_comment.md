# Prevent missing platformos-check-enable comments (`MissingEnableComment`)

When `platformos-check-disable` is used in the middle of a theme file, the corresponding `platformos-check-enable` comment should also be included.

## Check Details

This check aims at eliminating missing `platformos-check-enable` comments.

:-1: Example of **incorrect** code for this check:

```liquid
<!doctype html>
<html>
  <head>
    {% # platformos-check-disable ParserBlockingJavaScript %}
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
    {% # platformos-check-disable ParserBlockingJavaScript %}
    <script src="https://cdnjs.com/jquery.min.js"></script>
    {% # platformos-check-enable ParserBlockingJavaScript %}
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

[codesource]: /lib/platformos_check/checks/missing_enable_comment.rb
[docsource]: /docs/checks/missing_enable_comment.md
