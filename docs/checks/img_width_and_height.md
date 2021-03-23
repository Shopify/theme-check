# Width and height attributes on image tags (`ImgWidthAndHeight`)

This check exists to prevent [cumulative layout shift][cls] (CLS) in themes.

The absence of `width` and `height` attributes on an `img` tag prevents the browser from knowing the aspect ratio of the image before it is downloaded. Unless another technique is used to allocate space, the browser will consider the image to be of height 0 until it is loaded.

This has numerous nefarious implications:

1. [This causes layout shift as images start appearing one after the other.][codepenshift] Text starts flying down the page as the image pushes it down.
2. [This breaks lazy loading.][codepenlazy] When all images have a height of 0px, every image is inside the viewport. And when everything is in the viewport, everything gets loaded. There's nothing lazy about it!

The fix is easy. Make sure the `width` and `height` attribute are set on the `img` tag and that the CSS width of the image is set.

Note: The width and height attributes of an image do not have  units.

## Check Details

This check is aimed at eliminating content layout shift in themes by enforcing the use of the `width` and `height` attributes on `img` tags.

:-1: Examples of **incorrect** code for this check:

```liquid
<img alt="cat" src="cat.jpg">
<img alt="cat" src="cat.jpg" width="100px" height="100px">
<img alt="{{ image.alt }}" src="{{ image.src }}">
```

:+1: Examples of **correct** code for this check:

```liquid
<img alt="cat" src="cat.jpg" width="100" height="200">
<img
  alt="{{ image.alt }}"
  src="{{ image.src }}"
  width="{{ image.width }}"
  height="{{ image.height }}"
>
```

**NOTE:** The CSS `width` of the `img` should _also_ be set for the image to be responsive.

## Check Options

The default configuration for this check is the following:

```yaml
ImgWidthAndHeight:
  enabled: true
```

## When Not To Use It

There are some cases where you can avoid content-layout shift without needing the width and height attributes:

- When the aspect-ratio of the displayed image should be independent of the uploaded image. In those cases, the solution is still the padding-top hack with an `overflow: hidden container`.
- When you are happy with the padding-top hack.

In those cases, it is fine to disable this check with the comment. 

It is otherwise unwise to disable this check, since it would negatively impact the mobile search ranking of the merchants using your theme.

## Version

This check has been introduced in Theme Check 0.6.0.

## Resources

- [Cumulative Layout Shift Reference][cls]
- [Codepen illustrating the impact of width and height on layout shift][codepenshift]
- [Codepen illustrating the impact of width and height on lazy loading][codepenlazy]
- [Rule Source][codesource]
- [Documentation Source][docsource]

[cls]: https://web.dev/cls/
[codepenshift]: https://codepen.io/charlespwd/pen/YzpxPEp?editors=1100
[codepenlazy]: https://codepen.io/charlespwd/pen/abZmqXJ?editors=0111
[aspect-ratio]: https://caniuse.com/mdn-css_properties_aspect-ratio
[codesource]: /lib/theme_check/checks/img_aspect_ratio.rb
[docsource]: /docs/checks/img_aspect_ratio.md
