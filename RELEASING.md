## Releasing Theme Check

1. Check the Semantic Versioning page for info on how to version the new release: http://semver.org

2. Create a PR to update the version in `lib/theme_check/version.rb`

3. Merge your PR to master

4. On [Shipit](https://shipit.shopify.io/shopify/theme-check/rubygems), deploy your commit.

## Homebrew Release Process

1. Release `theme-check` on RubyGems by following the steps in the previous section.

2. Generate the homebrew formula.

   ```bash
   rake package
   ```

3. Copy the formula over in the [`homebrew-shopify`](https://github.com/Shopify/homebrew-shopify) repository.

   ```bash
   VERSION=X.X.X
   cp packaging/builds/$VERSION/theme-check ../homebrew-shopify
   ```

4. Create a branch + a commit on the [`homebrew-shopify`](https://github.com/Shopify/homebrew-shopify) repository.

   ```bash
   git checkout -b "bump/theme-check-$VERSION"
   git add theme-check.rb
   git commit -m "Bump theme-check version to $VERSION"
   ```

5. Create a pull-request for those changes on the [`homebrew-shopify`](https://github.com/Shopify/homebrew-shopify) repository.

   ```bash
   # shortcut if you have `hub` installed
   hub compare "master:bump/theme-check-$VERSION"
   ```
