## Releasing Theme Check

1. Check the Semantic Versioning page for info on how to version the new release: http://semver.org

2. Run the following command to update the version in `lib/theme_check/version.rb` and replace the `THEME_CHECK_VERSION` placeholder in the documentation for new rules:

   ```bash
   VERSION="X.X.X"
   rake prerelease[$VERSION]
   ```

   **NOTE:** command line enthusiasts can run `scripts/release <version>` to automate steps 2-4.

3. Run [`git changelog`](https://github.com/tj/git-extras) to update `CHANGELOG.md`.

4. Commit your changes and make a PR.

   ```bash
   git checkout -b "bump/theme-check-$VERSION"
   git add docs/checks CHANGELOG.md lib/theme_check/version.rb
   git commit -m "Bump theme-check version to $VERSION"
   hub compare "main:bump/theme-check-$VERSION"
   ```

5. Merge your PR to main.

6. On [Shipit](https://shipit.shopify.io/shopify/theme-check/rubygems), deploy your commit.

7. [Create a GitHub release](https://github.com/Shopify/theme-check/releases/new) for the change.

   ```
   VERSION=v1.X.Y
   git fetch origin
   git fetch origin --tags
   git reset origin $VERSION
   gh release create -t $VERSION
   ```

   (It's a good idea to copy parts of the CHANGELOG in there)


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
   hub compare "main:bump/theme-check-$VERSION"
   ```

## Shopify CLI Release Process

1. Release `theme-check` on RubyGems by following the steps in the previous section.

2. Update the `theme-check` version in [`shopify-cli`](https://github.com/shopify/shopify-cli)'s `shopify-cli.gemspec` file.

3. Run `bundle update theme-check` and get an updated `Gemfile.lock`

4. Create a branch + a commit on the [`shopify-cli`](https://github.com/Shopify/shopify-cli) repository.

   ```bash
   VERSION=X.X.X
   git checkout -b "bump/theme-check-$VERSION"
   git add Gemfile.lock
   git add shopify-cli.gemspec
   git commit -m "Bump theme-check version to $VERSION"
   ```

5. Create a pull-request for those changes on the [`shopify-cli`](https://github.com/Shopify/shopify-cli) repository.

   ```bash
   # shortcut if you have `hub` installed
   hub compare "main:bump/theme-check-$VERSION"
   ```
