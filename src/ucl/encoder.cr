module UCL
  class Encoder
    EMITTERS = {
      "json"         => UCL::LibUCL::Emitters::UCL_EMIT_JSON,
      "json_compact" => UCL::LibUCL::Emitters::UCL_EMIT_JSON_COMPACT,
      "config"       => UCL::LibUCL::Emitters::UCL_EMIT_CONFIG,
      "yaml"         => UCL::LibUCL::Emitters::UCL_EMIT_YAML,
      "msgpack"      => UCL::LibUCL::Emitters::UCL_EMIT_MSGPACK,
      "max"          => UCL::LibUCL::Emitters::UCL_EMIT_MAX,
    }

    DEFAULT_EMITTER = "config"

    def self.encode(object, emit_type = DEFAULT_EMITTER)
      emit_type = EMITTERS[emit_type]
      ucl_object = to_ucl_object(object)
      String.new UCL::LibUCL.object_emit(ucl_object, emit_type)
    end

    private def self.to_ucl_object(object)
      case object
      when Array
        array = UCL::LibUCL.object_typed_new(UCL::LibUCL::Types::UCL_ARRAY)
        object.each do |item|
          UCL::LibUCL.array_append(array, to_ucl_object(item))
        end
        array
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
      when String
        UCL::LibUCL.object_from_string(object)
      when Bool
        UCL::LibUCL.object_from_bool(object)
      when Int
        UCL::LibUCL.object_from_int(object)
      when Float
        UCL::LibUCL.object_from_double(object)
      when Nil
        UCL::LibUCL.object_typed_new(UCL::LibUCL::Types::UCL_NULL)
      when Time::Span
        UCL::LibUCL.object_from_double(object.to_i.to_f)
      else
        raise UCL::Error::TypeError.new("#{object.class.name}##{object.inspect} is not UCL serializable")
      end
    end
  end
end
