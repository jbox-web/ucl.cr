module UCL
  class Validator
    def self.validate(schema : String, string : String) : Bool
      schema = UCL::Parser.parse(schema)
      string = UCL::Parser.parse(string)
      do_validation(schema, string)
    end

    private def self.do_validation(schema, string) : Bool
      error = UCL::LibUCL::SchemaError.new
      UCL::LibUCL.object_validate(schema, string, pointerof(error))

      if error.code != UCL::LibUCL::SchemaErrorCode::UCL_SCHEMA_OK
        message = ""
        error.msg.each do |char|
          next if char == 0
          str = String.new(pointerof(char))
          message += str
        end

        raise UCL::Error::SchemaError.new(message)
      end

      true
    end
  end
end
