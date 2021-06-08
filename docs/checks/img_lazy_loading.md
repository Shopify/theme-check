# Lazy loading image tags (`ImgLazyLoading`)

Lazy loading is a strategy to identify resources as non-blocking (non-critical) and load these only when needed. It's a way to shorten the length of the critical rendering path, which translates into reduced page load times.

Lazy loading can occur on different moments in the application, but it typically happens on some user interactions such as scrolling and navigation.

Very often, webpages contain many images that contribute to data-usage and how fast a page can load. Most of those images are off-screen (non-critical), requiring user interaction (an example being scroll) in order to view them.

_Quoted from [MDN - Lazy loading][mdn]_

## Check Details

This check is aimed at defering loading non-critical images.

:-1: Examples of **incorrect** code for this check:

```liquid
<img src="a.jpg">

<!-- Replaces lazysize.js -->
<img src="a.jpg" class="lazyload">

<!-- `auto` is deprecated -->
<img src="a.jpg" loading="auto">
```

:+1: Examples of **correct** code for this check:

```liquid
<img src="a.jpg" loading="lazy">

<!-- `eager` is also accepted, but prefer `lazy` -->
<img src="a.jpg" loading="eager">
```

## Check Options

The default configuration for this check is the following:

```yaml
ImgLazyLoading:
  enabled: true
```

## When Not To Use It

If you don't want to defer loading of images, then it's safe to disable this rule.

## Version

This check has been introduced in Theme Check 0.10.0.

## Resources

- [Rule Source][codesource]
- [Documentation Source][docsource]
- [MDN - Lazy loading][mdn]

[codesource]: /lib/theme_check/checks/img_lazy_loading.rb
[docsource]: /docs/checks/img_lazy_loading.md
[mdn]: https://developer.mozilla.org/en-US/docs/Web/Performance/Lazy_loading
