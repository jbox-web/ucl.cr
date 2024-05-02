module UCL
  class Decoder
    def self.decode(string : String) : UCL::Value::Type
      object = UCL::Parser.parse(string)
      from_ucl_object(object)
    end

    private def self.from_ucl_object(object)
      result = convert_ucl_object(object)

      if !object.value.next.null? && object.value.type != UCL::LibUCL::Types::UCL_OBJECT.value
        result = [result] of UCL::Value::Type

        loop do
          object = object.value.next
          break if object.null?

          result << convert_ucl_object(object)
        end
      end

      result
    end

    private def self.convert_ucl_object(object)
      case object.value.type
      when UCL::LibUCL::Types::UCL_OBJECT.value
        hash = Value.new
        iterate_ucl_object(object) do |child|
          key = String.new UCL::LibUCL.object_key(child)
          hash[key] = from_ucl_object(child)
        end
        hash.to_h
      when UCL::LibUCL::Types::UCL_ARRAY.value
        array = [] of UCL::Value::Type
        iterate_ucl_object(object) do |child|
          array << from_ucl_object(child)
        end
        array
      when UCL::LibUCL::Types::UCL_STRING.value
        String.new UCL::LibUCL.object_to_string(object)
      when UCL::LibUCL::Types::UCL_BOOLEAN.value
        UCL::LibUCL.object_to_boolean(object)
      when UCL::LibUCL::Types::UCL_INT.value
        UCL::LibUCL.object_to_int(object)
      when UCL::LibUCL::Types::UCL_FLOAT.value
        UCL::LibUCL.object_to_double(object)
      when UCL::LibUCL::Types::UCL_TIME.value
        UCL::LibUCL.object_to_double(object)
      when UCL::LibUCL::Types::UCL_NULL.value
        nil
      else
        raise UCL::Error::ConversionError.new("Unsupported object type: #{object.value.type}")
      end
    end

    private def self.iterate_ucl_object(object, &)
      iterator = UCL::LibUCL.object_iterate_new(object)
      loop do
        ptr = UCL::LibUCL.object_iterate_safe(iterator, true)
        break if ptr.null?

        yield ptr
      end
    ensure
      UCL::LibUCL.object_iterate_free(iterator) if iterator
    end
  end
end
