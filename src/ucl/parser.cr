module UCL
  class Parser
    DEFAULT_FLAGS = UCL::LibUCL::ParserFlags::UCL_PARSER_NO_TIME | UCL::LibUCL::ParserFlags::UCL_PARSER_NO_IMPLICIT_ARRAYS

    def self.parse(string : String, flags = DEFAULT_FLAGS)
      parser = new(flags)
      parser.parse(string)
    end

    @parser : UCL::LibUCL::Parser*

    def initialize(flags = DEFAULT_FLAGS)
      @parser = UCL::LibUCL.new(flags)
    end

    def parse(string : String)
      load_string(string)
      check_error
      load_result
    end

    private def load_string(string)
      UCL::LibUCL.add_string(@parser, string, string.size)
    end

    private def check_error
      error = UCL::LibUCL.get_error(@parser)
      raise UCL::Error::DecoderError.new(String.new(error)) unless error.null?
    end

    private def load_result
      UCL::LibUCL.get_object(@parser)
    end
  end
end
