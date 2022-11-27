# Troubleshooting

## Issues with Language Server 

### Language server erroring out on startup

The following error can cause language server to crash:
```bash
Calling `DidYouMean::SPELL_CHECKERS.merge!(error_name => spell_checker)' has been deprecated. Please call `DidYouMean.correct_error(error_name, spell_checker)' instead.
/Users/johndoe/.gem/ruby/3.1.2/gems/bundler-2.2.22/lib/bundler/spec_set.rb:91:in `block in materialize': Could not find ruby-prof-0.18.0 in any of the sources (Bundler::GemNotFound)
```

Confirm the version of theme-check matches the version in the wrapper in `~/bin/theme-language-server`. If it doesn't match the ruby version, run the following from the theme-check directory:

```bash
chruby 3.1.2 #your `~/bin/theme-language-server` ruby version
bundle install
```

### Language server changes not propogating to your IDE

Look at logs for language server and check the response for initialize. If it looks like this, you're pointing to the Shopify CLI and not the language server in the repo:

```json
    "serverInfo": {
        "name": "/opt/homebrew/bin/shopify",
        "version": "1.10.3"
    }
```

Check the config for your IDE/completion engine and confirm the Shopify CLI path isn't present (this by default overrides theme-check pointing to the repo's language server). If you're using VS Code this would be in your `settings.json`. 

The response for initialize should look like this:

```json
    "serverInfo": {
        "name": "/Users/johndoe/src/github.com/Shopify/theme-check/bin/theme-check-language-server",
        "version": "1.10.3"
    }
```

If this isn't an issue, confirm the theme check repo's version of ruby matches the ruby version of your theme. If it doesn't, from the theme-check repo run:

```bash
chruby 3.1.2 #your theme ruby version
bundle install
```

### Language server sends an `initialize()` request to the client and stops

To debug, confirm these steps are included in your local language server startup script:

```bash 
export THEME_CHECK_DEBUG=true
export THEME_CHECK_DEBUG_LOG_FILE="/tmp/theme-check-debug.log"
touch "$THEME_CHECK_DEBUG_LOG_FILE"
```

An example script can be found [here](/CONTRIBUTING.md#run-language-server).

Open `/tmp/theme-check-debug.log` in your IDE. Check if there are any exceptions being raised by language server. 

If there are no exceptions, check if there are any logs that aren't in jsonrpc. The language server and client use stdin and stdout to communicate using jsonrpc. Debugging statements that aren't in a jsonrpc format might trigger unexpected behavior (this includes any logs from language server or echo statements in your language server script).


