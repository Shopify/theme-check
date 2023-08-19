# Troubleshooting

## Issues with Language Server

### Language server erroring out on startup

The following error can cause language server to crash:
```bash
Calling `DidYouMean::SPELL_CHECKERS.merge!(error_name => spell_checker)' has been deprecated. Please call `DidYouMean.correct_error(error_name, spell_checker)' instead.
/Users/johndoe/.gem/ruby/3.1.2/gems/bundler-2.2.22/lib/bundler/spec_set.rb:91:in `block in materialize': Could not find ruby-prof-0.18.0 in any of the sources (Bundler::GemNotFound)
```

Confirm the version of platformos-check matches the version in the wrapper in `~/bin/platformos-check-language-server`. If it doesn't match the ruby version, run the following from the platformos-check directory:

```bash
chruby 3.1.2 #your `~/bin/platformos-check-language-server` ruby version
bundle install
```

### Language server sends an `initialize()` request to the client and stops

To debug, confirm these steps are included in your local language server startup script:

```bash
export PLATFORMOS_CHECK_DEBUG=true
export PLATFORMOS_CHECK_DEBUG_LOG_FILE="/tmp/platformos-check-debug.log"
touch "$PLATFORMOS_CHECK_DEBUG_LOG_FILE"
```

An example script can be found [here](/CONTRIBUTING.md#run-language-server).

Open `/tmp/platformos-check-debug.log` in your IDE. Check if there are any exceptions being raised by language server.

If there are no exceptions, check if there are any logs that aren't in jsonrpc. The language server and client use stdin and stdout to communicate using jsonrpc. Debugging statements that aren't in a jsonrpc format might trigger unexpected behavior (this includes any logs from language server or echo statements in your language server script).

