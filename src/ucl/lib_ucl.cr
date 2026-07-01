module UCL
  # Raw C bindings to the native `libucl` library. This is the only place that
  # talks to C directly; every other class goes through it.
  #
  # The enums, structs and `fun` declarations mirror libucl's headers exactly —
  # their order and integer widths are ABI-sensitive and must not be changed
  # independently of the C library.
  @[Link("ucl")]
  lib LibUCL
    # Type tag carried by every `UclObject` (the `type` field). Matches
    # libucl's `ucl_type_t`.
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

    # Output formats accepted by `object_emit`. Matches libucl's
    # `ucl_emitter_t`; the string keys in `UCL::Encoder::EMITTERS` map onto these.
    enum Emitters
      UCL_EMIT_JSON
      UCL_EMIT_JSON_COMPACT
      UCL_EMIT_CONFIG
      UCL_EMIT_YAML
      UCL_EMIT_MSGPACK
      UCL_EMIT_MAX
    end

    # Result code stored in `SchemaError#code` after `object_validate`.
    # `UCL_SCHEMA_OK` means the data conforms; anything else is a failure.
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

    # Bit flags passed to `new` to tune parsing. Combine with `|`; the shard's
    # default set lives in `UCL::Parser::DEFAULT_FLAGS`.
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

    # Opaque parser handle (`struct ucl_parser`). Only ever used through a
    # pointer; the dummy field exists because Crystal forbids empty structs.
    struct Parser
      # Error: empty structs are disallowed
      iv : Int64
    end

    # Raw storage for a scalar `UclObject` (`union` in `ucl_object_s`). The
    # active member depends on the object's `Types` tag: `iv` int, `sv` string,
    # `dv` double, `av`/`ov`/`ud` array/object/userdata pointers.
    union Value
      iv : LibC::LongLong
      sv : LibC::Char*
      dv : LibC::Double
      av : Void*
      ov : Void*
      ud : Void*
    end

    # Mirror of libucl's `ucl_object_s`. `next`/`prev` form the sibling list
    # used for implicit arrays (see `UCL::Decoder`); `type` holds a `Types` value.
    struct UclObject
      value : Value
      key : LibC::Char*
      next : UclObject*
      prev : UclObject*
      keylen : LibC::UInt
      len : LibC::UInt
      ref : LibC::UInt
      flags : LibC::UShort
      type : LibC::UShort
      trash_stack : StaticArray(LibC::UChar*, 2)
    end

    # Populated by `object_validate`. `msg` is a fixed 128-byte C string that
    # `UCL::Validator` decodes into the raised error message.
    struct SchemaError
      code : SchemaErrorCode
      msg : StaticArray(LibC::Char, 128)
      obj : UclObject*
    end

    # Opaque cursor returned by `object_iterate_new`.
    alias Iterator = Void*

    # Parsing: allocate a parser, feed it a buffer, then read the error/result.
    fun new = ucl_parser_new(flags : LibC::Int) : Parser*
    fun add_string = ucl_parser_add_string(parser : Parser*, data : LibC::Char*, len : LibC::SizeT) : Bool
    # Loads and parses a file by path, handling file vars and relative includes.
    fun add_file = ucl_parser_add_file(parser : Parser*, filename : LibC::Char*) : Bool
    fun get_error = ucl_parser_get_error(parser : Parser*) : LibC::Char*
    # Returns a NEW owned reference to the top object (the caller must
    # `object_unref` it); freeing the parser only drops the parser's own ref.
    fun get_object = ucl_parser_get_object(parser : Parser*) : UclObject*
    # Releases the parser. Safe to call once the top object has been obtained
    # via `get_object` — that object keeps its own reference and stays alive.
    fun parser_free = ucl_parser_free(parser : Parser*) : Void
    # Decrements an object's reference count, freeing it (and, transitively, the
    # objects it owns) when the count reaches zero.
    fun object_unref = ucl_object_unref(object : UclObject*) : Void

    # Scalar accessors: read an object's key and coerce its value to a C type.
    fun object_key = ucl_object_key(object : UclObject*) : LibC::Char*
    fun object_to_int = ucl_object_toint(object : UclObject*) : LibC::LongLong
    fun object_to_double = ucl_object_todouble(object : UclObject*) : LibC::Double
    fun object_to_string = ucl_object_tostring(object : UclObject*) : LibC::Char*
    fun object_to_boolean = ucl_object_toboolean(object : UclObject*) : Bool

    # Iteration over the children of an object/array. The iterator must be freed.
    fun object_iterate_new = ucl_object_iterate_new(object : UclObject*) : Iterator
    fun object_iterate_safe = ucl_object_iterate_safe(object : Iterator, flags : Bool) : UclObject*
    fun object_iterate_free = ucl_object_iterate_free(iter : Iterator) : Void

    # Emit, validate, and mutate object trees.
    fun object_emit = ucl_object_emit(object : UclObject*, emit_type : Emitters) : LibC::Char*
    # Length-aware variant: required for binary formats (msgpack) whose output
    # can contain embedded NUL bytes. Writes the byte length into *len.
    fun object_emit_len = ucl_object_emit_len(object : UclObject*, emit_type : Emitters, len : LibC::SizeT*) : LibC::UChar*
    fun object_validate = ucl_object_validate(schema : UclObject*, object : UclObject*, error : SchemaError*) : Bool
    fun array_append = ucl_array_append(UclObject*, UclObject*) : Bool
    fun object_replace_key = ucl_object_replace_key(top : UclObject*, elt : UclObject*, key : LibC::Char*, keylen : LibC::SizeT, copy_key : Bool) : Bool

    # Constructors: build a typed object or wrap a scalar C value.
    fun object_typed_new = ucl_object_typed_new(type : Types) : UclObject*
    fun object_from_int = ucl_object_fromint(iv : LibC::LongLong) : UclObject*
    fun object_from_bool = ucl_object_frombool(bv : Bool) : UclObject*
    fun object_from_double = ucl_object_fromdouble(dv : LibC::Double) : UclObject*
    fun object_from_string = ucl_object_fromstring(str : LibC::Char*) : UclObject*
  end
end
