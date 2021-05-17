## Releasing Theme Check

1. Check the Semantic Versioning page for info on how to version the new release: http://semver.org

2. Run the following command to update the version in `lib/theme_check/version.rb` and replace the `THEME_CHECK_VERSION` placeholder in the documentation for new rules:

   ```bash
   VERSION="X.X.X"
   rake prerelease[$VERSION]
   ```

3. Run [`git changelog`](https://github.com/tj/git-extras) to update `CHANGELOG.md`.

4. Commit your changes and make a PR.

5. Merge your PR to master.

6. On [Shipit](https://shipit.shopify.io/shopify/theme-check/rubygems), deploy your commit.

## Homebrew Release Process

1. Release `theme-check` on RubyGems by following the steps in the previous section.

2. Generate the homebrew formula.

   ```bash
   rake package
   ```

3. Copy the formula over in the [`homebrew-shopify`](https://github.com/Shopify/homebrew-shopify) repository.

   ```bash
   VERSION=X.X.X
   cp packaging/builds/$VERSION/theme-check.rb ../homebrew-shopify
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
