# platformOS Check ✅ - A linter for platformOS

PlaformOS Check is a tool that helps you follow platformOS recommendations & best practices by analyzing the Liquid inside your app.

![](docs/preview.png)

## Supported Checks

Theme Check currently checks for the following:

✅ Liquid syntax errors
✅ JSON syntax errors
✅ Missing snippet & section templates
✅ Unused `{% assign ... %}`
✅ Unused snippet templates
✅ Template length
✅ Deprecated tags
✅ Unknown tags
✅ Unknown filters
✅ Missing or extra spaces inside `{% ... %}` and `{{ ... }}`
✅ Using several `{% ... %}` instead of `{% liquid ... %}`
✅ Undefined objects
✅ Deprecated filters
✅ Missing `platformos-check-enable` comment

As well as checks that prevent easy to spot performance problems:

✅ Use of [parser-blocking](/docs/checks/parser_blocking_javascript.md) JavaScript
✅ [Use of non-platformOS domains for assets](/docs/checks/remote_asset.md)
✅ [Missing width and height attributes on `img` tags](/docs/checks/img_width_and_height.md)
✅ [Too much JavaScript](/docs/checks/asset_size_javascript.md)
✅ [Too much CSS](/docs/checks/asset_size_css.md)

For detailed descriptions and configuration options, [take a look at the complete list.](/docs/checks/)

With more to come! Suggestions welcome ([create an issue](https://github.com/Platform-OS/platformos-lsp/issues)).

## Requirements

- Ruby 2.7+

## Installation

TODO

## Configuration

Add a `.platformos-check.yml` file at the root of your app.

See [config/default.yml](config/default.yml) for available options & defaults.

## Disable checks with comments

Use Liquid comments to disable and re-enable all checks for a section of your file:

```liquid
{% # platformos-check-disable %}
{% assign x = 1 %}
{% # platformos-check-enable %}
```

Disable a specific check by including it in the comment:

```liquid
{% # platformos-check-disable UnusedAssign %}
{% assign x = 1 %}
{% # platformos-check-enable UnusedAssign %}
```

Disable multiple checks by including them as a comma-separated list:

```liquid
{% # platformos-check-disable UnusedAssign,SpaceInsideBraces %}
{%assign x = 1%}
{% # platformos-check-enable UnusedAssign,SpaceInsideBraces %}
```

Disable checks for the _entire document_ by placing the comment on the first line:

```liquid
{% # platformos-check-disable SpaceInsideBraces %}
{%assign x = 1%}
```

## Exit Code and `--fail-level`

Use the `--fail-level` (default: `error`) flag to configure the exit code of platformos-check. Useful in CI scenarios.

Example:

```
# Make CI fail on styles warnings, suggestions, and errors
platformos-check --fail-level style path_to_app

# Make CI fail on suggestions, and errors
platformos-check --fail-level suggestion path_to_app

# Make CI fail on errors
platformos-check path_to_app
```

There are three fail levels:

- `error`
- `suggestion`
- `style`

Exit code meanings:

- 0: Success!
- 1: Your code doesn't pass the checks
- 2: There's a bug in platformos-check

If you would like to change the severity of a check, you can do so with the `severity` attribute. Example:

```yaml
DeprecateLazysizes:
  enabled: true
  severity: error
```

## Language Server Configurations

- `platformosCheck.checkOnOpen` (default: `true`) makes it so theme check runs on file open.
- `platformosCheck.checkOnChange` (default: `true`) makes it so theme check runs on file change.
- `platformosCheck.checkOnSave` (default: `true`) makes it so theme check runs on file save.
- `platformosCheck.onlySingleFileChecks` (default: `false`) makes it so we only check the opened files and disable "whole theme" checks (e.g. UnusedSnippet, TranslationKeyExists)

⚠️ **Note:** Quickfixes only work on a freshly checked file. If any of those configurations are turned off, you will need to rerun platformos-check in order to apply quickfixes.

In VS Code, these can be set directly in your `settings.json`.

## Contributing

For guidance on contributing, refer to this [doc](/CONTRIBUTING.md)
