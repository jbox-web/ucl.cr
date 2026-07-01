module UCL
  # Typed output formats accepted by `UCL.dump` / `UCL::Encoder.encode`.
  #
  # Prefer this over the legacy string form (`"json"`, ...): a wrong member is
  # a compile-time error instead of a runtime `EncoderError`.
  enum Emitter
    Json
    JsonCompact
    Config
    Yaml
    Msgpack

    # Maps to the raw libucl emitter.
    def to_lib : UCL::LibUCL::Emitters
      case self
      in Json        then UCL::LibUCL::Emitters::UCL_EMIT_JSON
      in JsonCompact then UCL::LibUCL::Emitters::UCL_EMIT_JSON_COMPACT
      in Config      then UCL::LibUCL::Emitters::UCL_EMIT_CONFIG
      in Yaml        then UCL::LibUCL::Emitters::UCL_EMIT_YAML
      in Msgpack     then UCL::LibUCL::Emitters::UCL_EMIT_MSGPACK
      end
    end
  end

  # Serializes a Crystal object into a UCL/JSON/YAML/MsgPack string by building
  # a libucl object tree and emitting it. Backs `UCL.dump`.
  class Encoder
    # Maps the emitter names accepted by `.encode` to their libucl counterparts.
    EMITTERS = {
      "json"         => UCL::LibUCL::Emitters::UCL_EMIT_JSON,
      "json_compact" => UCL::LibUCL::Emitters::UCL_EMIT_JSON_COMPACT,
      "config"       => UCL::LibUCL::Emitters::UCL_EMIT_CONFIG,
      "yaml"         => UCL::LibUCL::Emitters::UCL_EMIT_YAML,
      "msgpack"      => UCL::LibUCL::Emitters::UCL_EMIT_MSGPACK,
      "max"          => UCL::LibUCL::Emitters::UCL_EMIT_MAX,
    }

    # Emitter used when none is given: `"config"` (UCL output).
    DEFAULT_EMITTER = "config"

    # Serializes *object* using *emit_type*, a typed `UCL::Emitter` or one of the
    # legacy string keys of `EMITTERS`.
    #
    # Raises `UCL::Error::EncoderError` for an unknown string *emit_type*, and
    # `UCL::Error::TypeError` for a non-`String` hash key or an unsupported
    # value type.
    def self.encode(object, emit_type : String | Emitter = DEFAULT_EMITTER) : String
      build_ucl_object(object, resolve_emitter(emit_type))
    end

    # Resolves a typed emitter to its libucl counterpart.
    private def self.resolve_emitter(emit_type : Emitter) : UCL::LibUCL::Emitters
      emit_type.to_lib
    end

    # Resolves a legacy string emitter, raising on an unknown key.
    private def self.resolve_emitter(emit_type : String) : UCL::LibUCL::Emitters
      EMITTERS[emit_type]? ||
        raise UCL::Error::EncoderError.new("Unknown emitter format: #{emit_type}")
    end

    # Builds the libucl object tree for *object*, emits it with *emitter* and
    # returns the result as a Crystal `String`.
    #
    # Uses the length-aware `object_emit_len` so binary formats (msgpack) that
    # contain embedded NUL bytes are not truncated.
    private def self.build_ucl_object(object, emitter)
      ucl_object = to_ucl_object(object)
      len = LibC::SizeT.new(0)
      ptr = UCL::LibUCL.object_emit_len(ucl_object, emitter, pointerof(len))
      raise UCL::Error::EncoderError.new("Failed to emit UCL object") if ptr.null?

      # String.new copies the bytes, so the libucl buffer can be freed right
      # after. libucl mallocs it and documents that the caller must free it.
      String.new(ptr, len)
    ensure
      LibC.free(ptr.as(Void*)) if ptr && !ptr.null?
      # Releasing the top object frees the whole tree we built: append/insert
      # transfer ownership of children to their container.
      UCL::LibUCL.object_unref(ucl_object) if ucl_object
    end

    # Recursively converts a Crystal *object* into a libucl `UclObject*`.
    #
    # Hashes become UCL objects (keys must be `String`), arrays become UCL
    # arrays, and scalars map to the matching `ucl_object_from*` constructor.
    # `Time::Span` is stored as its whole number of seconds; `Nil` becomes a
    # typed null.
    #
    # Raises `UCL::Error::TypeError` for a non-`String` key or an unsupported
    # value type.
    private def self.to_ucl_object(object)
      case object
      when Hash
        hash = UCL::LibUCL.object_typed_new(UCL::LibUCL::Types::UCL_OBJECT)
        object.each do |key, value|
          if key.is_a?(String)
            UCL::LibUCL.object_replace_key(hash, to_ucl_object(value), key, 0, true)
          else
            raise UCL::Error::TypeError.new("UCL only supports string keys: #{key}")
          end
        end
        hash
      when Array
        array = UCL::LibUCL.object_typed_new(UCL::LibUCL::Types::UCL_ARRAY)
        object.each do |item|
          UCL::LibUCL.array_append(array, to_ucl_object(item))
        end
        array
      when String
        UCL::LibUCL.object_from_string(object)
      when Bool
        UCL::LibUCL.object_from_bool(object)
      when Int
        UCL::LibUCL.object_from_int(object)
      when Float
        UCL::LibUCL.object_from_double(object)
      when Time::Span
        UCL::LibUCL.object_from_double(object.total_seconds)
      when Nil
        UCL::LibUCL.object_typed_new(UCL::LibUCL::Types::UCL_NULL)
      else
        raise UCL::Error::TypeError.new("#{object.class.name}##{object.inspect} is not UCL serializable")
      end
    end
  end
end
