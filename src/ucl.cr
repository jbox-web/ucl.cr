require "./ucl/*"

module UCL
  VERSION = "0.1.0"

  def self.load(string : String, flags = UCL::Parser::DEFAULT_FLAGS) : UCL::Value::Type
    Decoder.decode(string, flags)
  end

  def self.dump(object, emit_type = UCL::Encoder::DEFAULT_EMITTER) : String
    Encoder.encode(object, emit_type)
  end
end
