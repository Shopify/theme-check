# Discourage use of parser-blocking `script_tag` filter (`ParserBlockingScriptTag`)

The `script_tag` filter emits a parser-blocking script tag.

See the [ParserBlockingJavaScript check documentation][parser_blocking_javascript] for why this is generally discouraged.

## Check Details

This check is aimed at eliminating parser-blocking JavaScript on themes.

:-1: Examples of **incorrect** code for this check:

```liquid
<!-- The script_tag filter outputs a parser-blocking script -->
{{ 'app-code.js' | asset_url | script_tag }}
```

:+1: Examples of **correct** code for this check:

```liquid
<!-- Good. Using the asset_url filter + defer -->
<script src="{{ 'theme.js' | asset_url }}" defer></script>

<!-- Also good. Using the asset_url filter + async -->
<script src="{{ 'theme.js' | asset_url }}" async></script>
```

## Check Options

The default configuration for this check is the following:

```yaml
ParserBlockingScriptTag:
  enabled: true
```

## When Not To Use It

This should only be turned off with the `theme-check-disable` comment when there's no better way to accomplish what you're doing than with a parser-blocking script.

It is discouraged to turn this rule off.

## Version

This check has been introduced in Theme Check 0.9.0.

## Resources

- [ParserBlockingJavaScript check][parser_blocking_javascript]
- [Documentation Source][docsource]

[parser_blocking_javascript]: /docs/checks/parser_blocking_javascript.md
[docsource]: /docs/checks/parser_blocking_script_tag.md
