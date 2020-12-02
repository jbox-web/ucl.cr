module UCL
  @[Link("ucl")]
  lib LibUCL
    enum Types : UInt16
      UCL_OBJECT
      UCL_ARRAY
      UCL_INT
      UCL_FLOAT
      UCL_STRING
      UCL_BOOLEAN
      UCL_TIME
      UCL_USERDATA
      UCL_NULL
    end

    enum Emitters
      UCL_EMIT_JSON
      UCL_EMIT_JSON_COMPACT
      UCL_EMIT_CONFIG
      UCL_EMIT_YAML
      UCL_EMIT_MSGPACK
      UCL_EMIT_MAX
    end

    enum SchemaErrorCode
      UCL_SCHEMA_OK
      UCL_SCHEMA_TYPE_MISMATCH
      UCL_SCHEMA_INVALID_SCHEMA
      UCL_SCHEMA_MISSING_PROPERTY
      UCL_SCHEMA_CONSTRAINT
      UCL_SCHEMA_MISSING_DEPENDENCY
      UCL_SCHEMA_EXTERNAL_REF_MISSING
      UCL_SCHEMA_EXTERNAL_REF_INVALID
      UCL_SCHEMA_INTERNAL_ERROR
      UCL_SCHEMA_UNKNOWN
    end

    enum ParserFlags
      UCL_PARSER_DEFAULT            = 0        # No special flags
      UCL_PARSER_KEY_LOWERCASE      = (1 << 0) # Convert all keys to lower case
      UCL_PARSER_ZEROCOPY           = (1 << 1) # Parse input in zero-copy mode if possible
      UCL_PARSER_NO_TIME            = (1 << 2) # Do not parse time and treat time values as strings
      UCL_PARSER_NO_IMPLICIT_ARRAYS = (1 << 3) # Create explicit arrays instead of implicit ones
      UCL_PARSER_SAVE_COMMENTS      = (1 << 4) # Save comments in the parser context
      UCL_PARSER_DISABLE_MACRO      = (1 << 5) # Treat macros as comments
      UCL_PARSER_NO_FILEVARS        = (1 << 6) # Do not set file vars
    end

    struct Parser
      iv : Int64
    end

    union Value
      iv : Int64
      sv : Pointer(UInt8)
      dv : Int64
      av : Pointer(Int32)
      ov : Pointer(Int32)
      ud : Pointer(Int32)
    end

    struct UclObject
      value : Value
      key : Pointer(UInt8)
      next : UclObject*
      prev : UclObject*
      keylen : UInt32
      len : UInt32
      ref : UInt32
      flags : UInt16
      type : UInt16
    end

    fun new = ucl_parser_new(flags : Int64) : Parser*
    fun add_string = ucl_parser_add_string(parser : Parser*, data : Pointer(UInt8), len : Int64) : Bool
    fun get_error = ucl_parser_get_error(parser : Parser*) : Pointer(UInt8)
    fun get_object = ucl_parser_get_object(parser : Parser*) : UclObject*

    fun object_key = ucl_object_key(object : UclObject*) : Pointer(UInt8)
    fun object_to_int = ucl_object_toint(object : UclObject*) : Int64
    fun object_to_double = ucl_object_todouble(object : UclObject*) : Float64
    fun object_to_string = ucl_object_tostring(object : UclObject*) : Pointer(UInt8)
    fun object_to_boolean = ucl_object_toboolean(object : UclObject*) : Bool

    fun object_iterate_new = ucl_object_iterate_new(object : UclObject*) : Pointer(Int32)
    fun object_iterate_safe = ucl_object_iterate_safe(object : Pointer(Int32), flags : Bool) : UclObject*
    fun object_iterate_free = ucl_object_iterate_free(iter : Pointer(Int32)) : Void

    fun object_emit = ucl_object_emit(object : UclObject*, emit_type : Int64) : Pointer(UInt8)
    fun array_append = ucl_array_append(UclObject*, UclObject*) : Bool
    fun object_replace_key = ucl_object_replace_key(top : UclObject*, elt : UclObject*, key : Pointer(UInt8), keylen : Int64, copy_key : Bool) : Bool

    fun object_typed_new = ucl_object_typed_new(ucl_type_t : Int64) : UclObject*
    fun object_from_int = ucl_object_fromint(iv : Int64) : UclObject*
    fun object_from_bool = ucl_object_frombool(bv : Bool) : UclObject*
    fun object_from_double = ucl_object_fromdouble(dv : Float64) : UclObject*
    fun object_from_string = ucl_object_fromstring(str : Pointer(UInt8)) : UclObject*
  end
end
