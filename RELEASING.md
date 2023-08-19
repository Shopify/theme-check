## Releasing platformOS Check

1. Check the Semantic Versioning page for info on how to version the new release: http://semver.org

2. Run the following command to update the version in `lib/platformos_check/version.rb` and replace the `PLATFORMOS_CHECK_VERSION` placeholder in the documentation for new rules:

   ```bash
   VERSION="X.X.X"
   rake prerelease[$VERSION]
   ```

3. Run [`git changelog`](https://github.com/tj/git-extras) to update `CHANGELOG.md`.

4. Commit your changes and make a PR.

   ```bash
   git checkout -b "bump/platformos-check-$VERSION"
   git add docs/checks CHANGELOG.md lib/platformos_check/version.rb
   git commit -m "Bump platformos-check version to $VERSION"
   hub compare "main:bump/platformos-check-$VERSION"
   ```

5. Merge your PR to main.

6. On [Shipit](https://shipit.shopify.io/shopify/platformos-check/rubygems), deploy your commit.

7. [Create a GitHub release](https://github.com/Shopify/platformos-check/releases/new) for the change.

   ```
   VERSION=v1.X.Y
   git fetch origin
   git fetch origin --tags
   git reset origin $VERSION
   gh release create -t $VERSION
   ```

   (It's a good idea to copy parts of the CHANGELOG in there)
