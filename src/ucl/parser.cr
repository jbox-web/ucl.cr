module UCL
  class Parser
    def self.parse(string)
      parser = new
      parser.parse(string)
    end

    @parser : UCL::LibUCL::Parser*

    def initialize
      @parser = UCL::LibUCL.new(0)
    end

    def parse(string)
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
