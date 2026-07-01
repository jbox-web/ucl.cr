module UCL
  # Converts a parsed libucl object tree into native Crystal values.
  #
  # Backs `UCL.load`. Repeated keys are always decoded as explicit arrays: the
  # decoder forces `UCL_PARSER_NO_IMPLICIT_ARRAYS` on top of the caller's flags
  # (see `decode`), because libucl's implicit-array iteration flattens repeated
  # *object* values and cannot be reconstructed faithfully here.
  class Decoder
    # Parses *string* and returns the decoded Crystal value.
    #
    # `UCL_PARSER_NO_IMPLICIT_ARRAYS` is always OR-ed into *flags* so that
    # repeated keys — scalars *and* objects — decode to Crystal arrays instead
    # of being merged/lost.
    #
    # Raises `UCL::Error::DecoderError` on a parse error and
    # `UCL::Error::ConversionError` on an unsupported libucl type.
    def self.decode(string : String, flags = UCL::Parser::DEFAULT_FLAGS) : UCL::Value::Type
      flags |= UCL::LibUCL::ParserFlags::UCL_PARSER_NO_IMPLICIT_ARRAYS
      object = UCL::Parser.parse(string, flags)
      convert_ucl_object(object)
    ensure
      # `parse` handed us an owned reference; release the whole tree once the
      # native values have been copied into Crystal objects.
      UCL::LibUCL.object_unref(object) if object
    end

    # Loads and decodes the UCL file at *path*. Same flag handling and ownership
    # contract as `.decode`.
    #
    # Raises `UCL::Error::DecoderError` if the file cannot be read or parsed.
    def self.decode_file(path : String, flags = UCL::Parser::DEFAULT_FLAGS) : UCL::Value::Type
      flags |= UCL::LibUCL::ParserFlags::UCL_PARSER_NO_IMPLICIT_ARRAYS
      object = UCL::Parser.parse_file(path, flags)
      convert_ucl_object(object)
    ensure
      UCL::LibUCL.object_unref(object) if object
    end

    # Converts one libucl object into the matching Crystal value based on its
    # type tag. Objects become hashes and arrays become arrays (both recursing);
    # scalars map to their native type; `UCL_TIME` is returned as a `Float64`
    # of seconds.
    #
    # With `NO_IMPLICIT_ARRAYS` forced (see `decode`), repeated keys are real
    # `UCL_ARRAY` objects, so no implicit `next`-chain walking is needed.
    #
    # Raises `UCL::Error::ConversionError` for any unhandled type.
    private def self.convert_ucl_object(object)
      case object.value.type
      when UCL::LibUCL::Types::UCL_OBJECT.value
        hash = {} of String => UCL::Value::Type
        iterate_ucl_object(object) do |child|
          key = String.new UCL::LibUCL.object_key(child)
          hash[key] = convert_ucl_object(child)
        end
        hash
      when UCL::LibUCL::Types::UCL_ARRAY.value
        array = [] of UCL::Value::Type
        iterate_ucl_object(object) do |child|
          array << convert_ucl_object(child)
        end
        array
      when UCL::LibUCL::Types::UCL_STRING.value
        String.new UCL::LibUCL.object_to_string(object)
      when UCL::LibUCL::Types::UCL_BOOLEAN.value
        UCL::LibUCL.object_to_boolean(object)
      when UCL::LibUCL::Types::UCL_INT.value
        UCL::LibUCL.object_to_int(object)
      when UCL::LibUCL::Types::UCL_FLOAT.value
        UCL::LibUCL.object_to_double(object)
      when UCL::LibUCL::Types::UCL_TIME.value
        # Round-trip note: time decodes to a Float64 of seconds, not a
        # Time::Span. Encoding a Time::Span produces the same numeric form, so
        # decode(encode(span)) yields a Float, not the original span. The
        # default flags also parse time as a string (NO_TIME); this branch only
        # applies when a caller enables time parsing.
        UCL::LibUCL.object_to_double(object)
      when UCL::LibUCL::Types::UCL_NULL.value
        nil
      else
        raise UCL::Error::ConversionError.new("Unsupported object type: #{object.value.type}")
      end
    end

    # Yields each child of *object* using a libucl safe iterator, freeing the
    # iterator afterwards even if the block raises.
    private def self.iterate_ucl_object(object, &)
      iterator = UCL::LibUCL.object_iterate_new(object)
      loop do
        ptr = UCL::LibUCL.object_iterate_safe(iterator, true)
        break if ptr.null?

        yield ptr
      end
    ensure
      UCL::LibUCL.object_iterate_free(iterator) if iterator
    end
  end
end
