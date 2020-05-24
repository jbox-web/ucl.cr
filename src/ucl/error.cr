module UCL
  module Error
    class BaseError < Exception; end

    class DecoderError < BaseError; end

    class ConversionError < BaseError; end

    class TypeError < BaseError; end

    class SchemaError < BaseError; end
  end
end
