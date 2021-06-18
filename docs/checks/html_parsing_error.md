# Report HTML parsing errors (`HtmlParsingError`)

Report errors preventing the HTML from being parsed and analyzed by Theme Check.

## Check Details

This check is aimed at reporting HTML errors that prevent a file from being analyzed.

The HTML parser limits the number of attributes per element to 400, and the maximum depth of the DOM tree to 400 levels. If any one of those limits is reached, parsing stops, and all HTML offenses on this file are ignored.

:-1: Examples of **incorrect** code for this check:

```liquid
<img src="muffin.jpeg"
     data-attrbute-1=""
     data-attrbute-2=""
     ... up to
     data-attrbute-400="">
```

:+1: Examples of **correct** code for this check:

```liquid
<img src="muffin.jpeg">
```

## Check Options

The default configuration for this check is the following:

```yaml
HtmlParsingError:
  enabled: true
```

## When Not To Use It

If you don't care about HTML offenses.

## Version

This check has been introduced in Theme Check 0.10.2.

## Resources

- [Rule Source][codesource]
- [Documentation Source][docsource]

[codesource]: /lib/theme_check/checks/html_parsing_error.rb
[docsource]: /docs/checks/html_parsing_error.md
