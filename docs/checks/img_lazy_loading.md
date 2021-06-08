# Lazy loading image tags (`ImgLazyLoading`)

A brief paragraph explaining why the check exists.

## Check Details

This check is aimed at eliminating ...

:-1: Examples of **incorrect** code for this check:

```liquid
<img src="a.jpg">
```

:+1: Examples of **correct** code for this check:

```liquid
<img src="a.jpg" loading="lazy">
```

## Check Options

The default configuration for this check is the following:

```yaml
ImgLazyLoading:
  enabled: true
```

## When Not To Use It

If you don't want to ..., then it's safe to disable this rule.

## Version

This check has been introduced in Theme Check THEME_CHECK_VERSION.

## Resources

- [Rule Source][codesource]
- [Documentation Source][docsource]

[codesource]: /lib/theme_check/checks/img_lazy_loading.rb
[docsource]: /docs/checks/img_lazy_loading.md
