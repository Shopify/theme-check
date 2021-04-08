# Discourage use of third party domains for hosting assets (`RemoteAsset`)

Years ago, loading jQuery from a common CDN was good for performance because the browser cache could be reused across website. This is no longer true because browsers now include the domain from which the request was made in the cache key.

Therefore, this technique now makes things worse. Here's why:

* **The benefits of HTTP/2 prioritization are lost.** HTTP/2 prioritization is a mechanism used by servers. If different servers are used to deliver assets, there's no way to prioritize.
* **A new connection dance (DNS, TCP, TLS) must be done to start downloading the resource.** With HTTPS, this takes 5 round trips to achieve. The farther away the buyer is from that domain, the longer it takes.
* **The [slow start][slowstart] part of the Internet's TCP congestion control strategy must happen on every connection.** This means that the download "acceleration" we commonly observe must be repeated many times over.

The fix? Deliver as much as you can from a small number of connections. In a Shopify context, this is done by leveraging the `assets/` folder and the [URL filters][url_filters].

## Check Details

This check is aimed at eliminating unnecessary HTTP connections.

:-1: Examples of **incorrect** code for this check:

```liquid
<!-- Using multiple CDNs -->
<script src="https://cdnjs.cloudflare.com/ajax/libs/jquery/3.6.0/jquery.min.js" defer></script>
{{ "https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/css/bootstrap.min.css" | stylesheet_tag }}
<img src="https://example.com/heart.png" ...>

<!-- Missing img_url filter -->
<img src="{{ image }}" ...>
```

In the examples above, multiple connections are competing for resources, are accelerating download independently and are improperly prioritized.

:+1: Examples of **correct** code for this check:

```liquid
<!-- Good -->
<script src="{{ 'jquery.min.js' | asset_url }}" defer></script>
{{ 'bootstrap.min.css' | asset_url | stylesheet_tag }}

<!-- Better -->
<script src="{{ 'theme.js' | asset_url }}" defer></script>
{{ 'theme.css' | asset_url | stylesheet_tag }}

<!-- Images -->
<img src="{{ image | img_url }}" ...>
```

In the above, the JavaScript, CSS and images are all loading from the same connection. Making it so the browser and CDN can properly prioritize which assets are downloaded first while maintaining a "hot" connection that downloads fast.

This can be done by downloading the files from those CDNs directly into your theme's `assets/` folder.

Use the [`img_url` filter][img_url] for images.

## Check Options

The default configuration for this check is the following:

```yaml
RemoteAsset:
  enabled: true
```

## When Not To Use It

When the remote content is highly dynamic.

## Version

This check has been introduced in Theme Check 0.7.0.

## Resources

- [Announcement by Google][googleprivacy]
- [HTTP Cache Partioning Explainer](https://github.com/shivanigithub/http-cache-partitioning)
- [Slow Start][slowstart]
- [Rule Source][codesource]
- [Documentation Source][docsource]

[googleprivacy]: https://developers.google.com/web/updates/2020/10/http-cache-partitioning#resources
[codesource]: /lib/theme_check/checks/remote_asset.rb
[docsource]: /docs/checks/remote_asset.md
[slowstart]: https://en.wikipedia.org/wiki/TCP_congestion_control#Slow_start
[url_filters]: https://shopify.dev/docs/themes/liquid/reference/filters/url-filters
[img_url]: https://shopify.dev/docs/themes/liquid/reference/filters/url-filters#img_url
