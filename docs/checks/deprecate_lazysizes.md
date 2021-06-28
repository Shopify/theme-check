# Deprecate lazySizes (`DeprecateLazysizes`)

[lazysizes](https://github.com/aFarkas/lazysizes) is a common JavaScript library used to lazy load images, iframes and scripts.

## Check Details

This check is aimed at discouraging the use of the lazysizes JavaScript library

:-1: Examples of **incorrect** code for this check:

```liquid

<!-- Reports use of "lazyload" class -->
<img src="a.jpg" class="lazyload">

<!-- Reports use of "data-srcset" and "data-sizes" attribute. Reports data-sizes="auto" -->
<img
  alt="House by the lake"
  data-sizes="auto"
  data-srcset="small.jpg 500w,
  medium.jpg 640w,
  big.jpg 1024w"
  data-src="medium.jpg"
  class="lazyload"
/>

```

:+1: Examples of **correct** code for this check:

```liquid

<!-- Does not use lazySizes library. Instead uses native "loading" attribute -->
<img src="a.jpg" loading="lazy">

```

## Check Options

The default configuration for this check is the following:

```yaml
DeprecateLazysizes:
  enabled: true
```

## When Not To Use It

You should disable this rule if you want to support lazy loading of images in older browser that don't support the loading="lazy" attribute yet.

## Version

This check has been introduced in Theme Check 1.0.0.

## Resources

- [Rule Source][codesource]
- [Documentation Source][docsource]

[codesource]: /lib/theme_check/checks/deprecate_lazysizes.rb
[docsource]: /docs/checks/deprecate_lazysizes.md
