# Deprecate Bgsizes (`DeprecateBgsizes`)

The lazySizes bgset extension allows you to define multiple background images with a width descriptor. The extension will then load the best image size for the current viewport and device (https://github.com/aFarkas/lazysizes/tree/gh-pages/plugins/bgset)


## Check Details

This check is aimed at discouraging the use of the lazySizes bgset plugin 

:-1: Examples of **incorrect** code for this check:

```liquid

<!-- Reports use of "lazyload" class and "data-bgset" attribute -->

<script src="ls.bgset.min.js"></script>
<script src="lazysizes.min.js"></script>
<div class="lazyload" data-bgset="image-200.jpg 200w, image-300.jpg 300w, image-400.jpg 400w" data-sizes="auto">
</div>

```

:+1: Examples of **correct** code for this check:

```liquid

<!-- Uses the CSS image-set() attribute instead of "data-bgset" -->
<!-- CSS Stylesheet -->
.box {
  background-image: -webkit-image-set(
    url("small-balloons.jpg") 1x,
    url("large-balloons.jpg") 2x);
  background-image: image-set(
    url("small-balloons.jpg") 1x,
    url("large-balloons.jpg") 2x);
}

<!-- HTML -->
<div class="box"></div>

```

## Check Options

The default configuration for this check is the following:

```yaml
DeprecateBgsizes:
  enabled: true
```

## When Not To Use It

You should disable this rule in older browsers that don't support the CSS image-set attribute.

## Version

This check has been introduced in Theme Check 1.0.0.

## Resources

- [Rule Source][codesource]
- [Documentation Source][docsource]

[codesource]: /lib/theme_check/checks/deprecate_bgsizes.rb
[docsource]: /docs/checks/deprecate_bgsizes.md
