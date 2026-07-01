module UCL
  # A thin, typed view over a decoded `UCL::Value::Type`, in the spirit of
  # `JSON::Any`. Lets callers navigate and coerce values without manual casts:
  #
  # ```
  # cfg = UCL.load_any(File.read("app.conf"))
  # cfg["server"]["port"].as_i  # => 8080
  # cfg["server"]["hosts"].as_a # => [UCL::Any, ...]
  # ```
  struct Any
    # The wrapped decoded value.
    getter raw : UCL::Value::Type

    def initialize(@raw : UCL::Value::Type)
    end

    # Returns the element for the object *key*, wrapped. Raises if the value is
    # not an object or the key is missing.
    def [](key : String) : Any
      Any.new(raw.as(Hash(String, UCL::Value::Type))[key])
    end

    # Returns the element at array *index*, wrapped. Raises if not an array.
    def [](index : Int) : Any
      Any.new(raw.as(Array(UCL::Value::Type))[index])
    end

    # Like `#[](String)` but returns `nil` when this is not an object or the key
    # is absent.
    def []?(key : String) : Any?
      hash = raw.as?(Hash(String, UCL::Value::Type))
      return nil unless hash && hash.has_key?(key)
      Any.new(hash[key])
    end

    # Like `#[](Int)` but returns `nil` when this is not an array or the index is
    # out of range.
    def []?(index : Int) : Any?
      array = raw.as?(Array(UCL::Value::Type))
      return nil unless array && index >= 0 && index < array.size
      Any.new(array[index])
    end

    {% for type, method in {String => "s", Int64 => "i", Float64 => "f", Bool => "bool"} %}
      # Coerces to `{{type}}`, raising `TypeCastError` on a mismatch.
      def as_{{method.id}} : {{type}}
        raw.as({{type}})
      end

      # Coerces to `{{type}}?`, returning `nil` on a mismatch.
      def as_{{method.id}}? : {{type}}?
        raw.as?({{type}})
      end
    {% end %}

    # Returns the array elements, each wrapped in `Any`. Raises if not an array.
    def as_a : Array(Any)
      raw.as(Array(UCL::Value::Type)).map { |e| Any.new(e) }
    end

    # Returns the object entries, each value wrapped in `Any`. Raises if not an
    # object.
    def as_h : Hash(String, Any)
      raw.as(Hash(String, UCL::Value::Type)).transform_values { |v| Any.new(v) }
    end
  end
end
