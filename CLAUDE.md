# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

`ucl.cr` is a Crystal shard providing bindings to [LibUCL](https://github.com/vstakhov/libucl), a universal configuration language library. It loads UCL/JSON config strings into native Crystal values, dumps Crystal objects back out in several formats, and validates data against UCL/JSON schemas.

The C library is a **git submodule** vendored at `ext/libucl`, built from source and installed into `/usr/local/lib`. The bindings link against it via `@[Link("ucl")]`.

## Toolchain & Tasks

This project uses [mise](https://mise.jdx.dev) (not asdf) for both the Crystal version and its task runner. All tasks are defined in `mise.toml`; run them with `mise <task>`.

First-time setup (requires `build-essential automake autoconf libtool` on Linux):

```sh
git submodule update --init --recursive   # fetch ext/libucl
mise libucl:build                          # autogen + configure + make in ext/libucl
mise libucl:install                        # copy libucl into /usr/local/lib (uses sudo)
mise dev:deps                              # shards install
```

Common tasks:

- `mise dev:spec` — run the spec suite (sets `LD_LIBRARY_PATH=/usr/local/lib`)
- `mise dev:build` / `mise release:build` — compile `src/ucl.cr` to `bin/ucl`
- `mise dev:format` — `crystal tool format src/`
- `mise dev:ameba` — static analysis via the vendored `bin/ameba`
- `mise dev:doc` — regenerate `docs/` with `crystal doc`

Run a single spec file/example directly (remember the lib path):

```sh
LD_LIBRARY_PATH=/usr/local/lib crystal spec spec/ucl/decoder_spec.cr
LD_LIBRARY_PATH=/usr/local/lib crystal spec spec/ucl/decoder_spec.cr:42
```

Note: on some Crystal installs the `shards` binary is missing from mise's bin dir — `mise dev:fix-shards-command` works around this.

## Architecture

Everything lives under the `UCL` module. `src/ucl.cr` exposes the public API — `UCL.load`, `UCL.load_any`, `UCL.load_file`, `UCL.dump`, `UCL.validate`, `UCL.valid?` — as thin wrappers that delegate to four single-responsibility classes. Data flows in one direction through each:

- **`LibUCL`** (`lib_ucl.cr`) — the raw C bindings: `Types`/`Emitters`/`ParserFlags`/`SchemaErrorCode` enums, the `UclObject` struct, and `fun` declarations. This is the only file that talks to C; everything else goes through it.
- **`Parser`** (`parser.cr`) — wraps a `ucl_parser_*` handle. `parse`/`parse_file` add the input, check `get_error` (raising `DecoderError`), return the raw owned `UclObject*`, and free the parser in `ensure`. `DEFAULT_FLAGS` = `NO_TIME | NO_IMPLICIT_ARRAYS`. Internal API (exposes raw C pointers) — not semver-covered.
- **`Decoder`** (`decoder.cr`) — recursively converts a `UclObject*` tree (via `Parser`) into native Crystal values, building plain `Hash`/`Array` directly and iterating children through `object_iterate_*`. It **forces `NO_IMPLICIT_ARRAYS`** on top of the caller's flags so repeated keys (scalars *and* objects) decode to real arrays; there is intentionally no `object.value.next` walking. Unrefs the tree when done.
- **`Encoder`** (`encoder.cr`) — the inverse: recursively builds a `UclObject*`, emits it via `object_emit_len` (length-aware, so binary msgpack isn't truncated at NUL), then `LibC.free`s the buffer and unrefs the tree. Formats come from the typed `UCL::Emitter` enum or the legacy string keys in `EMITTERS` (`config` default; also `json`, `json_compact`, `yaml`, `msgpack`).
- **`Validator`** (`validator.cr`) — parses schema and data (honouring `flags`), calls `object_validate`, and on failure raises `SchemaError` carrying the reconstructed message (`String.new(msg.to_unsafe)`) and the libucl `code`. Unrefs both trees.

**`Value`** (`value.cr`) is a `struct` wrapping `Hash(String, Type)` (so copies share the same hash). `Type` is the recursive union `UCL.load` returns; `Value` itself is **not** in the union (objects decode to plain `Hash`).

**`Any`** (`any.cr`) is a `JSON::Any`-style typed view over a `Type`, returned by `UCL.load_any`. It adds `#[]`/`#[]?` navigation and `as_s`/`as_i`/`as_f`/`as_bool` (+ nilable variants), `as_a`, `as_h` so callers avoid manual casts.

**`Error`** (`error.cr`) defines the exception hierarchy, all under `UCL::Error::BaseError`.

### Working with the C boundary

- The type/enum values in `lib_ucl.cr` mirror libucl's C headers exactly — changing order or width breaks the ABI.
- **Memory ownership:** `get_object` returns an *owned* ref (caller must `object_unref`); `emit_len` mallocs a buffer the caller must `LibC.free`. Every parse frees its parser; every decode/validate/encode unrefs the trees it built. Preserve these frees when touching the C paths (verified leak-free via macOS `leaks`).
- Pass byte lengths, not char counts: use `String#bytesize` for `add_string`, and `String.new(ptr, len)` for binary output.
- C strings come back as `LibC::Char*` and must be wrapped with `String.new(...)`; comparisons against C enum values use `.value` (e.g. `object.value.type == UCL::LibUCL::Types::UCL_OBJECT.value`).

## Conventions

- Public methods use explicit return types (`: UCL::Value::Type`, `: String`, `: Bool`); helper methods are `private def self.*`.
- Raise a specific `UCL::Error::*` subclass for each failure mode (unknown emitter → `EncoderError`, non-string hash key or unserializable value → `TypeError`, unsupported decode type → `ConversionError`, parse/read failure → `DecoderError`).
- `src/ucl.cr` requires `json`/`yaml` so `Value#to_json`/`#to_yaml` compile.
- This is a library, so `shard.lock` is gitignored intentionally (see `.gitignore`).
