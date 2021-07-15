
v1.2.0 / 2021-07-15
==================

  * Add Windows Support ([#364](https://github.com/shopify/theme-check/issues/364))
  * Ignore empty `{{}}` in SpaceInsideBraces ([#350](https://github.com/shopify/theme-check/issues/350))
  * Switch to main branch
  * Minor documentation fixes

v1.1.0 / 2021-07-06
==================

  * Add `--fail-level` CLI flag to configure exit code
  * Refactor all theme file classes to inherit from `ThemeFile`
  * Fix `undefined method liquid?` error when scanning from LSP
  * Adding asset document links
  * Allow initializing theme app extension configuration files
  * Allow disabling registering mock Liquid tags w/ `ThemeCheck::Tags.register_tags = false`
  * Support Theme App Extensions
  * Add checks for theme app extension block JS/CSS
  * Disable Liquid::C when parsing Liquid templates

v1.0.0 / 2021-06-28
==================

  * Convert `AssetSizeCSS` to `HtmlCheck`
  * Add `DeprecateLazysizes` & `DeprecateBgsizes` checks
  * Allow hardcoded CDN urls in `RemoteAsset`
  * Bump `LiquidTag` `min_consecutive_statements` default to 5
  * Exclude {% javascript %} and {% stylesheet %} from line counts in `TemplateLength`
  * Bump `TemplateLength` `max_length` default to 500
  * Fix `StringScanner#skip(String)` not being supported on some Rubies
  * Fix `ParsingHelpers#outside_of_strings` handling of empty strings
  * Update to support new `{% render %}` syntax
  * Converted `AssetSizeJavaScript` to `HtmlCheck`

v0.10.2 / 2021-06-18
==================

  * Fix error when parsing a template with lots of HTML attributes.
  * Add `HtmlParsingError` check for reporting errors during HTML parsing.

v0.10.1 / 2021-06-11
==================

  * Fix LSP diagnostics not being merged properly when analyzing a single file.
    Causing VSCode problems not being cleared after fixing.

v0.10.0 / 2021-06-08
==================

  * Add ImgLazyLoading check for recommending loading="lazy" attribute

v0.9.1 / 2021-06-04
==================

  * Convert `RemoteAsset` into an `HtmlCheck`
  * Move Liquid logic from `RemoteAsset` to a new `AssetUrlFilters` check

v0.9.0 / 2021-05-28
==================

  * Introduce HtmlCheck, and convert ParserBlockingJavaScript & ImgWidthAndHeight to it
  * Move `script-tag` validation from ParserBlockingJavaScript to ParserBlockingScriptTag
  * Add ability to ignore individual checks using file patterns
  * Introduce single file and whole theme checks to optimize LSP diagnostics
  * Fix TemplateLength counter not being reseted on each document
  * Add missing category to ValidHTMLTranslation
  * Set Ruby default encodings to UTF-8 to fix encoding issues
  * Add ContentForHeaderModification check to prevent relying on the content of ``content_for_header`
  * Fix `Content-Length` in LSP responses
  * Fix disabling checks that emit offences in `on_end`
  * Fix completion bug in `filter_completion_provider`

v0.8.3 / 2021-05-17
==================

  * Making sure VERSION is set before referencing it

v0.8.2 / 2021-05-14
===================

  * Bump NestedSnippet max_nesting_level to 3
  * Add a message to help debug errors, and timeout checks after 5 sec
  * Object Completions Everywhere!
  * Include operators to space inside braces check

0.8.1 / 2021-04-22
==================

  * Add consistent spacing around the pipe character (`|`) in variable expressions to the `SpaceInsideBrace` check ([#73](https://github.com/shopify/theme-check/issues/73))
  * Add ReCaptcha system translation ([#265](https://github.com/shopify/theme-check/issues/265))
  * Fix document links in `{% liquid %}` tags ([#263](https://github.com/shopify/theme-check/issues/263))
  * Fix theme-check-disable for checks based on regular expressions ([#242](https://github.com/shopify/theme-check/issues/242))
  * Fix VS Code crash on new window ([#264](https://github.com/shopify/theme-check/issues/264))
  * Rescue errors thrown by remote_asset_file

0.8.0 / 2021-04-13
==================

 * Set minimal Ruby version to 2.6

0.7.3 / 2021-04-13
==================

  * Refactor CLI option parsing

0.7.2 / 2021-04-12
==================

  * Fixup bug in RemoteAsset causing Language Server to break

0.7.1 / 2021-04-12
==================

  * Fix High CPU Bug in RemoteAsset check
  * Fix document link for render tags that trim whitespace.

0.7.0 / 2021-04-08
==================

  * Add [RemoteAsset Check](/docs/checks/remote_asset.md)
  * Fixes:
    * Don't hang on self closing img tags ([#247](https://github.com/shopify/theme-check/issues/247))
    * Fix document links from different root

0.6.0 / 2021-03-23
==================

  * Add [Snippet Completion](https://screenshot.click/23-22-5tyee-kv5vl.mp4) ([#223](https://github.com/shopify/theme-check/issues/223))
  * Add [Snippet Document Links](https://screenshot.click/23-09-71h84-pp23z.mp4) ([#223](https://github.com/shopify/theme-check/issues/223))
  * Add [ImgWidthAndHeight](/docs/checks/img_width_and_height.md) check ([#216](https://github.com/shopify/theme-check/issues/216))
  * Add [AssetSizeCSS](/docs/checks/asset_size_css.md) check ([#206](https://github.com/shopify/theme-check/issues/206))
  * Do not flag SystemTranslations as errors ([#114](https://github.com/shopify/theme-check/issues/114))
  * Do not complete deprecated filters ([#205](https://github.com/shopify/theme-check/issues/205))
  * Add `-C, --config path` support ([#213](https://github.com/shopify/theme-check/issues/213))

0.5.0 / 2021-03-12
==================

  * Add [AssetSizeJavaScript](/docs/checks/asset_size_javascript.md) check ([#194](https://github.com/Shopify/theme-check/pull/194))
  * Add [documentation for all checks](/docs/checks)
  * Make documentation for checks mandatory
  * Add link to documentation from within the editor (via `codeDescription` in the Language Server) (![Demo](https://screenshot.click/10-29-cjx7r-4asor.mp4))
  * Allow checks to have multiple categories
  * Fix multiple occurrences of UndefinedObject not being reported ([#192](https://github.com/shopify/theme-check/issues/192))

v0.4.0 / 2021-02-25
==================

  * Add Completion Engine ([#161](https://github.com/shopify/theme-check/issues/161))
  * Add init command to CLI ([#174](https://github.com/shopify/theme-check/issues/174))
  * Refactor start and end Position logic ([#172](https://github.com/shopify/theme-check/issues/172))

v0.3.3 / 2021-02-18
==================

  * Fix column_end issues ([#164](https://github.com/Shopify/theme-check/issues/164))
  * Fix stack overflow in UndefinedObject + UnusedAssign when snippets renders itself ([#165](https://github.com/Shopify/theme-check/issues/165))

v0.3.2 / 2021-02-17
==================

  * Ignore snippets in UndefinedObject check

v0.3.1 / 2021-02-16
===================

  * Fixup version flag

v0.3.0 / 2021-02-16
===================

  * Add ParserBlockingJavaScript Check ([#78](https://github.com/Shopify/theme-check/issues/78), [#146](https://github.com/Shopify/theme-check/issues/146))
  * Internal refactor to enable running theme-check in servers ([#145](https://github.com/Shopify/theme-check/issues/145), [#148](https://github.com/Shopify/theme-check/issues/148))
  * Add -v, --version flag ([#126](https://github.com/Shopify/theme-check/issues/126))
  * Exclude content of {% schema %} in line count for TemplateLength ([#140](https://github.com/Shopify/theme-check/issues/140))
  * Fix Language Server removed files bug ([#136](https://github.com/Shopify/theme-check/issues/136))
  * Add ignore config ([#147](https://github.com/Shopify/theme-check/issues/147))
  * Add ability to disable checks with comments ([#79](https://github.com/Shopify/theme-check/issues/79))
  * Adding checks for shopify plus objects in checkout ([#121](https://github.com/Shopify/theme-check/issues/121))

v0.2.2 / 2021-01-22
===================

  * [Language Server] Send empty dianogstics to flush errors
