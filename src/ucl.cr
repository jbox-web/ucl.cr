require "json"
require "yaml"
require "./ucl/*"

# Crystal bindings for [LibUCL](https://github.com/vstakhov/libucl), a universal
# configuration language.
#
# The top-level module exposes the whole public API as four convenience methods
# that delegate to the underlying `Decoder`, `Encoder` and `Validator`:
#
# ```
# require "ucl"
#
# data = UCL.load("foo = bar")    # => {"foo" => "bar"}
# UCL.dump(data)                  # => "foo = \"bar\";\n"
# UCL.valid?(schema, data_string) # => true / false
# ```
#
# ### Threading
#
# The wrapper holds no shared state — each call allocates its own parser — so it
# is safe to use from multiple fibers. Note that the underlying libucl calls are
# synchronous and **block the current thread** for the duration of a parse or
# emit; offload very large documents to a dedicated worker rather than running
# them on a latency-sensitive event loop.
module UCL
  # Version of this shard.
  VERSION = "0.1.0"

  # Parses a UCL (or JSON) *string* into native Crystal values.
  #
  # *flags* tunes the underlying libucl parser; see `UCL::Parser::DEFAULT_FLAGS`.
  #
  # ```
  # UCL.load("foo = bar") # => {"foo" => "bar"}
  # ```
  #
  # Raises `UCL::Error::DecoderError` on malformed input and
  # `UCL::Error::ConversionError` on an unsupported value type.
  def self.load(string : String, flags = UCL::Parser::DEFAULT_FLAGS) : UCL::Value::Type
    Decoder.decode(string, flags)
  end

  # Like `.load`, but wraps the result in a `UCL::Any` for typed, cast-free
  # navigation (`cfg["server"]["port"].as_i`).
  def self.load_any(string : String, flags = UCL::Parser::DEFAULT_FLAGS) : UCL::Any
    UCL::Any.new(load(string, flags))
  end

  # Loads and parses the UCL/JSON file at *path* into native Crystal values.
  #
  # Unlike `.load(File.read(path))`, libucl resolves file variables and relative
  # includes. *flags* tunes the parser; see `UCL::Parser::DEFAULT_FLAGS`.
  #
  # Raises `UCL::Error::DecoderError` if the file cannot be read or parsed.
  def self.load_file(path : String, flags = UCL::Parser::DEFAULT_FLAGS) : UCL::Value::Type
    Decoder.decode_file(path, flags)
  end

  # Serializes *object* to a string using the given *emit_type*.
  #
  # Valid emitters are `"config"` (the default, UCL), `"json"`, `"json_compact"`,
  # `"yaml"` and `"msgpack"`. See `UCL::Encoder::EMITTERS`.
  #
  # ```
  # UCL.dump({"foo" => "bar"})         # => "foo = \"bar\";\n"
  # UCL.dump({"foo" => "bar"}, "json") # => "{\n    \"foo\": \"bar\"\n}"
  # ```
  #
  # Raises `UCL::Error::EncoderError` for an unknown emitter and
  # `UCL::Error::TypeError` for a non-string key or unserializable value.
  def self.dump(object, emit_type : String | UCL::Emitter = UCL::Encoder::DEFAULT_EMITTER) : String
    Encoder.encode(object, emit_type)
  end

  # Validates the UCL/JSON *string* against the UCL/JSON *schema*.
  #
  # *flags* tunes the parser used for both the schema and the data; see
  # `UCL::Parser::DEFAULT_FLAGS`.
  #
  # Returns `true` when the data is valid, otherwise raises
  # `UCL::Error::SchemaError` with the message reported by libucl. Use `.valid?`
  # for a boolean result instead.
  def self.validate(schema : String, string : String, flags = UCL::Parser::DEFAULT_FLAGS) : Bool
    Validator.validate(schema, string, flags)
  end

  # Same as `.validate` but returns `false` instead of raising.
  #
  # Returns `false` both when *string* does not conform to *schema*
  # (`SchemaError`) and when either the schema or the data cannot be parsed
  # (`DecoderError`) — a predicate should never raise on bad input.
  def self.valid?(schema : String, string : String, flags = UCL::Parser::DEFAULT_FLAGS) : Bool
    validate(schema, string, flags)
  rescue UCL::Error::SchemaError | UCL::Error::DecoderError
    false
  end
end
