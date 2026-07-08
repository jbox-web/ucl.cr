# Instance-method sugar mirroring Crystal's `#to_json` / `#to_yaml`: reopens
# every type the `UCL::Encoder` knows how to serialize so callers can write
# `config.to_ucl` instead of `UCL.dump(config)`.
#
# ```
# {"foo" => "bar"}.to_ucl         # => "foo = \"bar\";\n"
# {"foo" => "bar"}.to_ucl("json") # => "{\n    \"foo\": \"bar\"\n}"
# ```
#
# Only the types handled by `UCL::Encoder#to_ucl_object` are reopened, so the
# method exists exactly where a serialization can succeed. `emit_type` accepts
# the same `String | UCL::Emitter` values as `UCL.dump`.
#
# `Hash#to_ucl` additionally guards its key type at compile time: a non-`String`
# key (`Hash(Int32, _)`) is a compile error rather than a runtime `TypeError`.
# Values are *not* checked, since the value type is often a broad union — a
# nested unsupported value still raises `UCL::Error::TypeError` at runtime.

class Hash(K, V)
  # Serializes `self` to UCL/JSON/YAML/MsgPack. See `UCL.dump`.
  #
  # The key type `K` is checked at compile time (UCL objects require `String`
  # keys). Values are not checked recursively: a nested unsupported value still
  # raises `UCL::Error::TypeError` at runtime.
  def to_ucl(emit_type : String | UCL::Emitter = UCL::Encoder::DEFAULT_EMITTER) : String
    {% raise "UCL only supports String hash keys, got Hash(#{K}, #{V})" unless K <= String %}
    UCL.dump(self, emit_type)
  end
end

struct NamedTuple
  # Serializes `self` to UCL/JSON/YAML/MsgPack, stringifying the `Symbol` keys.
  # See `UCL.dump`.
  def to_ucl(emit_type : String | UCL::Emitter = UCL::Encoder::DEFAULT_EMITTER) : String
    UCL.dump(self, emit_type)
  end
end

class Array
  # Serializes `self` to UCL/JSON/YAML/MsgPack. See `UCL.dump`.
  def to_ucl(emit_type : String | UCL::Emitter = UCL::Encoder::DEFAULT_EMITTER) : String
    UCL.dump(self, emit_type)
  end
end

class String
  # Serializes `self` to UCL/JSON/YAML/MsgPack. See `UCL.dump`.
  def to_ucl(emit_type : String | UCL::Emitter = UCL::Encoder::DEFAULT_EMITTER) : String
    UCL.dump(self, emit_type)
  end
end

struct Bool
  # Serializes `self` to UCL/JSON/YAML/MsgPack. See `UCL.dump`.
  def to_ucl(emit_type : String | UCL::Emitter = UCL::Encoder::DEFAULT_EMITTER) : String
    UCL.dump(self, emit_type)
  end
end

struct Int
  # Serializes `self` to UCL/JSON/YAML/MsgPack. See `UCL.dump`.
  def to_ucl(emit_type : String | UCL::Emitter = UCL::Encoder::DEFAULT_EMITTER) : String
    UCL.dump(self, emit_type)
  end
end

struct Float
  # Serializes `self` to UCL/JSON/YAML/MsgPack. See `UCL.dump`.
  def to_ucl(emit_type : String | UCL::Emitter = UCL::Encoder::DEFAULT_EMITTER) : String
    UCL.dump(self, emit_type)
  end
end

struct Nil
  # Serializes `self` (a typed UCL null) to UCL/JSON/YAML/MsgPack. See `UCL.dump`.
  def to_ucl(emit_type : String | UCL::Emitter = UCL::Encoder::DEFAULT_EMITTER) : String
    UCL.dump(self, emit_type)
  end
end

struct Time::Span
  # Serializes `self` (its whole number of seconds) to UCL. See `UCL.dump`.
  def to_ucl(emit_type : String | UCL::Emitter = UCL::Encoder::DEFAULT_EMITTER) : String
    UCL.dump(self, emit_type)
  end
end
