require "./ucl/*"

module UCL
  VERSION = "0.1.0"

  def self.load(string)
    Decoder.decode(string)
  end

  def self.dump(object, emit_type = Encoder::DEFAULT_EMITTER)
    Encoder.encode(object, emit_type)
  end
end
