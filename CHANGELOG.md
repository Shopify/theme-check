
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
