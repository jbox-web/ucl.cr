# LibUCL bindings for Crystal

[![GitHub license](https://img.shields.io/github/license/jbox-web/ucl.cr.svg)](https://github.com/jbox-web/ucl.cr/blob/master/LICENSE)
[![GitHub release](https://img.shields.io/github/release/jbox-web/ucl.cr.svg)](https://github.com/jbox-web/ucl.cr/releases/latest)
[![CI](https://github.com/jbox-web/ucl.cr/workflows/CI/badge.svg)](https://github.com/jbox-web/ucl.cr/actions)

[LibUCL](https://github.com/vstakhov/libucl) is a universal configuration language.

This shard is a Crystal wrapper around LibUCL. It lets you:

* **load** UCL/JSON configuration into native Crystal values,
* **dump** Crystal objects back to UCL, JSON, YAML or MsgPack,
* **validate** data against a UCL/JSON schema.

It was heavily inspired by [ucl](https://github.com/jbox-web/ucl) (Ruby).

## Requirements

This shard links against the native `libucl` library, which must be installed
on your system before you can compile or run anything.

The library is vendored as a git submodule (`ext/libucl`) and built from source.
You'll need the usual C build toolchain (`build-essential automake autoconf libtool`
on Debian/Ubuntu, or the equivalent on macOS).

```sh
# Fetch the vendored libucl source
git submodule update --init --recursive

# Build and install it into /usr/local/lib
mise libucl:build
mise libucl:install
```

> These tasks are defined in `mise.toml`. If you don't use [mise](https://mise.jdx.dev),
> run the equivalent commands by hand: `cd ext/libucl && ./autogen.sh && ./configure && make`,
> then copy `src/.libs/libucl.*` into `/usr/local/lib`.

## Installation

Add the dependency to your `shard.yml`:

```yaml
dependencies:
  ucl:
    github: jbox-web/ucl.cr
```

Then run `shards install`.

## Usage

```crystal
require "ucl"
```

### Load

Parse a UCL (or JSON) string into native Crystal values:

```crystal
UCL.load("foo = bar")
# => {"foo" => "bar"}
```

Load directly from a file (libucl resolves file variables and relative
includes, unlike `UCL.load(File.read(path))`):

```crystal
UCL.load_file("config.conf")
```

Repeated keys always decode to arrays (scalars *and* objects):

```crystal
UCL.load("s { a = 1 }\ns { b = 2 }")
# => {"s" => [{"a" => 1}, {"b" => 2}]}
```

For typed, cast-free access, use `load_any` — a `JSON::Any`-style wrapper:

```crystal
cfg = UCL.load_any(%(server { port = 8080, hosts = ["a", "b"] }))
cfg["server"]["port"].as_i        # => 8080
cfg["server"]["hosts"].as_a.map(&.as_s) # => ["a", "b"]
cfg["server"]["missing"]?         # => nil
```

### Dump

Serialize a Crystal object. The default emitter is `config` (UCL). Pick a format
with the typed `UCL::Emitter` enum (preferred) or the legacy string form —
`json`, `json_compact`, `yaml`, `msgpack`:

```crystal
UCL.dump({"foo" => "bar"})
# => "foo = \"bar\";\n"

UCL.dump({"foo" => "bar"}, UCL::Emitter::Json)
# => "{\n    \"foo\": \"bar\"\n}"

UCL.dump({"foo" => "bar"}, "json") # legacy string form still works
```

Hash keys must be strings; supported value types are `String`, `Bool`, `Int`,
`Float`, `Time::Span`, `Nil`, `Array` and `Hash`. Anything else raises
`UCL::Error::TypeError`.

### Validate

Check data against a UCL/JSON schema. `validate` raises
`UCL::Error::SchemaError` on mismatch; `valid?` returns a boolean instead:

```crystal
schema = File.read("schema.json")
data   = File.read("data.json")

UCL.validate(schema, data)  # => true, or raises UCL::Error::SchemaError
UCL.valid?(schema, data)    # => true / false
```

## Development

This project uses [mise](https://mise.jdx.dev) to manage the Crystal version and
common tasks (see `mise.toml`):

```sh
mise dev:deps     # shards install
mise dev:spec     # run the specs
mise dev:format   # crystal tool format src/
mise dev:ameba    # static analysis
```

The specs require the native `libucl` to be installed (see [Requirements](#requirements));
`dev:spec` sets `LD_LIBRARY_PATH=/usr/local/lib` for you.

## Contributing

1. Fork it (<https://github.com/jbox-web/ucl.cr/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## License

This shard is released under the [MIT License](LICENSE).
