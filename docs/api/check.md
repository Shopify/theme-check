# Check API

There are three types of checks currently supported:

## Liquid checks

For checking the Liquid code in `.liquid`.

All code inside `{% ... %}` or `{{ ... }}` is Liquid code.

Check the API of [`LiquidCheck`](/docs/api/liquid_check.md) for details.

## HTML checks

For checking HTML elements in `.liquid`.

If you need to checks a tag or its attributes, use an `HtmlCheck`.

Check the API of [`HtmlCheck`](/docs/api/html_check.md) for details.

## JSON checks

For checking the content of `.json` files, use a `JsonCheck`.

Check the API of [`JsonCheck`](/docs/api/html_check.md) for details.
