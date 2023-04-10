# Lazy loading image tags (`ImgLazyLoading`)

Lazy loading is a strategy to identify resources as non-blocking (non-critical) and load these only when needed. It's a way to shorten the length of the critical rendering path, which translates into reduced page load times.

Lazy loading can occur on different moments in the application, but it typically happens on some user interactions such as scrolling and navigation.

Very often, webpages contain many images that contribute to data-usage and how fast a page can load. Most of those images are off-screen (non-critical), requiring user interaction (an example being scroll) in order to view them.

_Quoted from [MDN - Lazy loading][mdn]_

As a general rule you should apply `loading="lazy"` to elements that are **not initially visible** when the page loads. Only images that require user interaction (scrolling, hovering, clicking etc.) to be seen can be safely lazy loaded without negatively impacting the rendering performance.

## Check Details

This check is aimed at deferring loading non-critical images.

:-1: Examples of **incorrect** code for this check:

```liquid
<img src="a.jpg">

<!-- Replaces lazysizes.js -->
<img data-src="a.jpg" class="lazyload">

<!-- `auto` is deprecated -->
<img src="a.jpg" loading="auto">
```

:+1: Examples of **correct** code for this check:

```liquid
<img src="a.jpg" loading="lazy">

<!-- `eager` is also accepted -->
<img src="a.jpg" loading="eager">
```

## Check Options

The default configuration for this check is the following:

```yaml
ImgLazyLoading:
  enabled: true
```

## When Not To Use It

There should be no cases where disabling this rule is needed. When it comes to rendering performance, it is generally better to specify `loading="eager"` as a default. You may want to do that for sections that are often placed in different parts of the page (top, middle, bottom), which makes it hard to reason about which value should be used.

## Version

This check has been introduced in Theme Check 0.10.0.

## Resources

- [Rule Source][codesource]
- [Documentation Source][docsource]
- [MDN - Lazy loading][mdn]

[codesource]: /lib/theme_check/checks/img_lazy_loading.rb
[docsource]: /docs/checks/img_lazy_loading.md
[mdn]: https://developer.mozilla.org/en-US/docs/Web/Performance/Lazy_loading
