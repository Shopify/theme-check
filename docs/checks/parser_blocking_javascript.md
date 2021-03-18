# Discourage use of parser-blocking JavaScript (`ParserBlockingJavaScript`)

The `defer` or `async` attributes are extremely important on script tags. When neither of those attributes are used, a script tag will block the construction and rendering of the DOM until the script is _loaded_, _parsed_ and _executed_. It also creates congestion on the Network, messes with the resource priorities and significantly delays the rendering of the page.

Considering that JavaScript on Shopify themes should always be used to progressively _enhance_ the experience of the site, themes should never make use of parser-blocking script tags.

As a general rule, use `defer` if the order of execution matters, `async` otherwise. When in doubt, choose either one and get 80/20 of the benefits.

## Check Details

This check is aimed at eliminating parser-blocking JavaScript on themes.

:-1: Examples of **incorrect** code for this check:

```liquid
<!-- The script_tag filter outputs a parser-blocking script -->
{{ 'app-code.js' | asset_url | script_tag }}

<!-- jQuery is typically loaded synchronously because inline scripts depend on $, don't do that. -->
<script src="https://code.jquery.com/jquery-3.6.0.min.js"></script>
...
<button id="thing">Click me!</button>
<script>
  $('#thing').click(() => {
    alert('Oh. Hi Mark!');
  });
</script>
```

:+1: Examples of **correct** code for this check:

```liquid
<!-- Good. Using the asset_url filter + defer -->
<script src="{{ 'theme.js' | asset_url }}" defer></script>

<!-- Also good. Using the asset_url filter + async -->
<script src="{{ 'theme.js' | asset_url }}" async></script>

<!-- Better than synchronous jQuery -->
<script src="https://code.jquery.com/jquery-3.6.0.min.js" defer></script>
...
<button id="thing">Click me!</button>
<script>
  // Because we're using `defer`, jQuery is guaranteed to
  // be loaded when DOMContentLoaded fires. This technique
  // could be used as a first step to refactor an old theme
  // that inline depends on jQuery.
  document.addEventListener('DOMContentLoaded', () => {
    $('#thing').click(() => {
      alert('Oh. Hi Mark!');
    });
  });
</script>

<!-- Even better. Web Native (no jQuery). -->
<button id="thing">Click Me</button>
<script>
  const button = document.getElementById('thing');
  button.addEventListener('click', () => {
    alert('Oh. Hi Mark!');
  });
</script>

<!-- Best -->
<script src="{{ 'theme.js' | asset_url }}" defer></script>
...
<button id="thing">Click Me</button>
```

## Check Options

The default configuration for this check is the following:

```yaml
ParserBlockingJavaScript:
  enabled: true
```

## When Not To Use It

This should only be turned off with the `theme-check-disable` comment when there's no better way to accomplish what you're doing than with a parser-blocking script.

It is discouraged to turn this rule off.

## Version

This check has been introduced in Theme Check 0.3.0.

## Resources

- [Lighthouse Render-Blocking Resources Audit][render-blocking]
- [Rule Source][codesource]
- [Documentation Source][docsource]

[render-blocking]: https://web.dev/render-blocking-resources/
[codesource]: /lib/theme_check/checks/parser_blocking_javascript.rb
[docsource]: /docs/checks/parser_blocking_javascript.md
