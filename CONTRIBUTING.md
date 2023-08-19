# Contributing to platformOS Check

## Standards

* Checks should do one thing, and do it well.
* PR should explain what the feature does, and why the change exists.
* PR should include any carrier specific documentation explaining how it works.
* Code _must_ be tested.
* Be consistent. Write clean code that follows [Ruby community standards](https://github.com/bbatsov/ruby-style-guide).
* Code should be generic and reusable.

## How to contribute

1. Fork it ( https://github.com/Platform-OS/platformos-lsp )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Run Language Server

If you're making changes to the language server and you want to debug, you can run the repo's version of `platformos-check-language-server`.

### Setup

Before configuring your IDE, run the following commands in a terminal:

  * Make sure you have a `$HOME/bin`
      ```bash
      mkdir -p $HOME/bin
      ```
  * Paste this script to create an executable wrapper in `$HOME/bin/platformos-check-language-server` for language server
      ```bash
      cat <<-'EOF' > $HOME/bin/platformos-check-language-server
      #!/usr/bin/env bash
      cd "$HOME/src/github.com/Platform-OS/platformos-lsp" &> /dev/null
      export PLATFORMOS_CHECK_DEBUG=true
      export PLATFORMOS_CHECK_DEBUG_LOG_FILE="/tmp/platformos-check-debug.log"
      touch "$PLATFORMOS_CHECK_DEBUG_LOG_FILE"
      gem env &>/dev/null
      bin/platformos-check-language-server
      EOF
      ```
  * Make the script executable
      ```bash
      chmod u+x $HOME/bin/platformos-check-language-server
      ```

#### Configure VS Code

TODO

#### Configure Vim

If you use `coc.nvim` as your completion engine, add this to your CocConfig:

```json
"languageserver": {
  "platformos-check": {
    "command": "/Users/<YOUR_USERNAME>/bin/platformos-check-language-server",
    "trace.server": "verbose",
    "filetypes": ["liquid"],
    "rootPatterns": [".platformos-check.yml, .pos"],
    "settings": {
      "platformosCheck": {
        "checkOnSave": true,
        "checkOnEnter": true,
        "checkOnChange": false
      }
    }
  }
```

### Confirm Setup

* In another terminal from the root of theme check run `tail -f /tmp/platformos-check-debug.log` to watch the server logs
* Restart your IDE, confirm the response for initialize in the logs is pointing to the language server in the `$HOME/bin` directory (the version will be different)

```json
    "serverInfo": {
        "name": "/Users/johndoe/bin/platformos-check-language-server",
        "version": "1.10.3"
    }
```


## Running Tests

```
bundle install
bundle exec rake
```

## Checking a pOS app

```
bin/platformos-check /path/to/your/app
```

## Creating a new "Check"

Run `bundle exec rake "new_check[MyNewCheckName]"` to generate all the files required to create a new check.

Check the [Check API](/docs/api/check.md) for how to implement a check. Also take a look at other checks in [lib/platformos_check/checks](/lib/platformos_check/checks).

We done implementing your check, add it to `config/default.yml` to enable it:

```yaml
MyNewCheckName:
  enabled: true
  ignore: []
```

If the check is configurable, the `initialize` argument names and default values should also be duplicated inside `config/default.yml`. eg.:

```ruby
class MyCheckName < LiquidCheck
  def initialize(muffin_mode: true)
    @muffin_mode = muffin_mode
  end
  # ...
end
```

```yaml
MyNewCheckName:
  enabled: true
  ignore: []
  muffin_mode: true
```

## Debugging

A couple of things are turned on when the `PLATFORMOS_CHECK_DEBUG` environment variable is set.

1. The check timeout is turned off. This means you can add `binding.pry` in tests and properly debug with `bundle exec rake tests:in_memory`
2. The `--profile` flag appears. You can now create Flamegraphs to inspect performance.

```
export PLATFORMOS_CHECK_DEBUG=true

# The following will behave slightly differently
bin/platformos-check ../dawn
bundle exec rake tests:in_memory

# The following becomes available
bin/platformos-check --profile ../dawn

# The LanguageServer will log the JSONRPC calls to STDERR
bin/platformos-check-language-server
```

### Profiling

`ruby-prof` and `ruby-prof-flamegraph` are both included as development dependencies.

#### Flamegraph

With the `--profile` flag, you can run platformos-check on a theme and the `ruby-prof-flamegraph` printer will output profiling information in a format [Flamegraph](/brendangregg/FlameGraph) understands.


**Setup:**

```bash
# clone the FlameGraph repo somewhere
git clone https://github.com/brendangregg/FlameGraph.git

# the flamegraph.pl perl script is in that repo
alias flamegraph=/path/to/FlameGraph/flamegraph.pl
```

**Profiling:**

```
# run platformos-check with --profile
# pass the output to flamegraph
# dump the output into an svg file
bin/platformos-check --profile ../dawn \
  | flamegraph --countname=ms --width=1750 \
  > /tmp/fg.svg

# open the svg file in Chrome to look at the flamegraph
chrome /tmp/fg.svg
```

What you'll see is an interactive version of the following image:

![flamegraph](docs/flamegraph.svg)

## Troubleshooting

If you run into issues during development, see the [troubleshooting guide](/TROUBLESHOOTING.md)
