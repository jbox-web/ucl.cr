require "./ucl/*"

module UCL
  VERSION = "0.1.0"

  def self.load(string : String) : UCL::Value::Type
    Decoder.decode(string)
  end

  def self.dump(object, emit_type = Encoder::DEFAULT_EMITTER) : String
    Encoder.encode(object, emit_type)
  end
end
