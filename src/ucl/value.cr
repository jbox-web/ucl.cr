module UCL
  # A thin wrapper around a `Hash(String, Type)`, and the namespace for the
  # `Type` union returned by the public API.
  #
  # `Value` behaves like a string-keyed hash (`#[]`, `#[]?`, `#[]=`, `#each`,
  # `#delete`) and can be serialized with `#to_json` / `#to_yaml`.
  #
  # NOTE: this is a `struct` wrapping a `Hash` (a reference). Copying a `Value`
  # shares the same underlying hash, so mutations are visible through every
  # copy — treat it as a handle, not a value type.
  struct Value
    # Every Crystal value a decoded UCL document can hold. The union is
    # recursive so nested arrays and objects are fully typed. Objects decode to
    # plain `Hash(String, Type)`, so `Value` itself is not part of the union.
    alias Type = Bool | Float64 | Float32 | Int64 | Int32 | String | Time | Nil | Array(Type) | Hash(String, Type)

    # Creates an empty value backed by a fresh `Hash(String, Type)`.
    def initialize
      @container = {} of String => Type
    end

    delegate each, to: @container
    delegate delete, to: @container
    delegate to_json, to: @container
    delegate to_yaml, to: @container
    delegate to_h, to: @container

    # Serializes the underlying hash to UCL/JSON/YAML/MsgPack. See `UCL.dump`.
    def to_ucl(emit_type : String | UCL::Emitter = UCL::Encoder::DEFAULT_EMITTER) : String
      UCL.dump(@container, emit_type)
    end

    # Returns the value for *key*, raising `KeyError` if it is missing.
    def [](key : String)
      @container[key]
    end

    # Returns the value for *key*, or `nil` if it is missing.
    def []?(key : String)
      @container[key]?
    end

    # Sets the *value* for *key*.
    def []=(key : String, value)
      @container[key] = value
    end

    # Returns the underlying `Hash(String, Type)`.
    def raw
      @container
    end
  end
end
