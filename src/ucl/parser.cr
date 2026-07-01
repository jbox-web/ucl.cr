module UCL
  # Low-level wrapper around a libucl parser handle. It turns a string into the
  # raw `UCL::LibUCL::UclObject*` tree consumed by `Decoder` and `Validator`.
  #
  # This is an internal building block that exposes raw C pointers: it is **not**
  # part of the public, semver-covered API and may change. Use `UCL.load` /
  # `UCL.load_file` instead.
  class Parser
    # Flags applied by default: parse time values as strings
    # (`UCL_PARSER_NO_TIME`) and produce explicit rather than implicit arrays
    # (`UCL_PARSER_NO_IMPLICIT_ARRAYS`). See `UCL::LibUCL::ParserFlags`.
    DEFAULT_FLAGS = UCL::LibUCL::ParserFlags::UCL_PARSER_NO_TIME | UCL::LibUCL::ParserFlags::UCL_PARSER_NO_IMPLICIT_ARRAYS

    # Parses *string* with a fresh parser and returns the raw libucl object.
    def self.parse(string : String, flags = DEFAULT_FLAGS)
      parser = new(flags)
      parser.parse(string)
    end

    # Parses the file at *path* with a fresh parser and returns the raw object.
    def self.parse_file(path : String, flags = DEFAULT_FLAGS)
      parser = new(flags)
      parser.parse_file(path)
    end

    @parser : UCL::LibUCL::Parser*

    # Allocates a new libucl parser configured with *flags*.
    def initialize(flags = DEFAULT_FLAGS)
      @parser = UCL::LibUCL.new(flags)
    end

    # Feeds *string* to the parser and returns the resulting `UclObject*`.
    #
    # The returned object is a NEW owned reference (see `LibUCL#get_object`); the
    # caller is responsible for `object_unref`-ing it. The parser itself is freed
    # here — `ensure` runs even on a parse error, so no parser handle leaks.
    #
    # Raises `UCL::Error::DecoderError` if libucl reports a parse error.
    def parse(string : String)
      load_string(string)
      check_error
      load_result
    ensure
      UCL::LibUCL.parser_free(@parser)
    end

    # Like `#parse`, but loads the UCL document from the file at *path* (libucl
    # resolves file vars and relative includes). Same ownership/free contract.
    #
    # Raises `UCL::Error::DecoderError` if the file cannot be read or parsed.
    def parse_file(path : String)
      load_file(path)
      check_error
      load_result
    ensure
      UCL::LibUCL.parser_free(@parser)
    end

    # Hands the input buffer to libucl for parsing.
    private def load_string(string)
      UCL::LibUCL.add_string(@parser, string, string.bytesize)
    end

    # Asks libucl to load and parse the file at *path*.
    private def load_file(path)
      UCL::LibUCL.add_file(@parser, path)
    end

    # Raises `UCL::Error::DecoderError` if libucl recorded a parse error.
    private def check_error
      error = UCL::LibUCL.get_error(@parser)
      raise UCL::Error::DecoderError.new(String.new(error)) unless error.null?
    end

    # Retrieves the top-level object produced by the parser.
    private def load_result
      UCL::LibUCL.get_object(@parser)
    end
  end
end
