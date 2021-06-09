# Check API

Theme Check uses static analysis. It parses theme files into an AST, and then calls the appropriate checks to analyze it.

An [AST](https://en.wikipedia.org/wiki/Abstract_syntax_tree) is a tree of node, representing the theme file.

Checks are Ruby classes with callback methods:
- `on_TYPE` that runs before a node of the specific TYPE is visited.
- `after_TYPE` that runs after a node of the specific TYPE is visited.

There are three types of checks currently supported:

- [`LiquidCheck`](/docs/api/liquid_check.md)
- [`HtmlCheck`](/docs/api/html_check.md)
- [`JsonCheck`](/docs/api/html_check.md)
