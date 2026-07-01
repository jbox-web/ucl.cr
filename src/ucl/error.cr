module UCL
  # Exception hierarchy raised by the shard. Every error inherits from
  # `Error::BaseError`, so `rescue UCL::Error::BaseError` catches them all.
  module Error
    # Base class for every error raised by UCL.
    class BaseError < Exception; end

    # Raised when libucl fails to parse the input string (see `UCL::Parser`).
    class DecoderError < BaseError; end

    # Raised when an unknown emitter format is requested (see `UCL::Encoder`).
    class EncoderError < BaseError; end

    # Raised when a decoded libucl object has an unsupported type (see `UCL::Decoder`).
    class ConversionError < BaseError; end

    # Raised when an object cannot be serialized: a non-`String` hash key or an
    # unsupported value type (see `UCL::Encoder`).
    class TypeError < BaseError; end

    # Raised by `UCL::Validator` when data does not conform to the schema.
    #
    # `#code` carries the underlying libucl `SchemaErrorCode` (e.g.
    # `UCL_SCHEMA_TYPE_MISMATCH`) for programmatic handling, when available.
    class SchemaError < BaseError
      getter code : UCL::LibUCL::SchemaErrorCode?

      def initialize(message : String? = nil, @code : UCL::LibUCL::SchemaErrorCode? = nil)
        super(message)
      end
    end
  end
end
