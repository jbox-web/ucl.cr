module UCL
  struct Value
    alias Type = Bool | Float64 | Float32 | Int64 | Int32 | String | Time | Nil | Value | Array(Type) | Hash(String, Type)

    def initialize
      @container = {} of String => Type
    end

    delegate each, to: @container
    delegate delete, to: @container
    delegate to_json, to: @container
    delegate to_yaml, to: @container
    delegate to_h, to: @container

    def [](key : String)
      @container[key]
    end

    def []?(key : String)
      @container[key]?
    end

    def []=(key : String, value)
      @container[key] = value
    end

    def raw
      @container
    end
  end
end
