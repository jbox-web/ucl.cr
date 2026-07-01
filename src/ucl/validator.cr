module UCL
  # Validates a UCL/JSON document against a UCL/JSON schema using libucl's
  # `ucl_object_validate`. Backs `UCL.validate` and `UCL.valid?`.
  class Validator
    # Parses both *schema* and *string* (with *flags*) and validates the data
    # against the schema.
    #
    # Returns `true` when valid, otherwise raises `UCL::Error::SchemaError` with
    # the message reported by libucl.
    def self.validate(schema : String, string : String, flags = UCL::Parser::DEFAULT_FLAGS) : Bool
      schema_obj = UCL::Parser.parse(schema, flags)
      data_obj = UCL::Parser.parse(string, flags)
      do_validation(schema_obj, data_obj)
    ensure
      # Both parses returned owned references; release them once validation is
      # done (or if do_validation raises SchemaError).
      UCL::LibUCL.object_unref(schema_obj) if schema_obj
      UCL::LibUCL.object_unref(data_obj) if data_obj
    end

    # Runs libucl's validation of *string* against *schema* (both already parsed
    # into `UclObject*`). On a non-OK result code it rebuilds the human message
    # from the fixed-size `SchemaError#msg` C char buffer and raises
    # `UCL::Error::SchemaError`; otherwise returns `true`.
    private def self.do_validation(schema, string) : Bool
      error = UCL::LibUCL::SchemaError.new
      UCL::LibUCL.object_validate(schema, string, pointerof(error))

      if error.code != UCL::LibUCL::SchemaErrorCode::UCL_SCHEMA_OK
        # `msg` is a fixed 128-byte, NUL-terminated C buffer; read it in one go
        # rather than byte-by-byte (the latter took the address of a stack copy
        # and read past it — undefined behaviour).
        message = String.new(error.msg.to_unsafe)
        raise UCL::Error::SchemaError.new(message, error.code)
      end

      true
    end
  end
end
