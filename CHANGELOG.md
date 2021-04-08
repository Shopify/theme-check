
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
