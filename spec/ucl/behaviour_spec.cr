require "../spec_helper"

describe UCL do
  describe ".load" do
    it "parses non-ASCII (multi-byte UTF-8) values without truncation" do
      UCL.load(%(key = "été")).should eq({"key" => "été"})
    end

    it "parses a multi-byte key" do
      UCL.load(%(clé = "value")).should eq({"clé" => "value"})
    end

    it "decodes empty input to an empty hash" do
      UCL.load("").should eq({} of String => UCL::Value::Type)
    end

    it "decodes whitespace-only input to an empty hash" do
      UCL.load("   \n  ").should eq({} of String => UCL::Value::Type)
    end

    it "decodes deeply nested structures" do
      result = UCL.load("a { b { c { d = [1, 2, [3, 4]] } } }")
      result.should eq({"a" => {"b" => {"c" => {"d" => [1, 2, [3, 4]]}}}})
    end

    it "honours custom parser flags (KEY_LOWERCASE)" do
      flags = UCL::LibUCL::ParserFlags::UCL_PARSER_KEY_LOWERCASE
      UCL.load("FOO = bar", flags).should eq({"foo" => "bar"})
    end

    context "with repeated keys" do
      default_flags = UCL::LibUCL::ParserFlags::UCL_PARSER_DEFAULT

      it "keeps repeated scalar keys as an array" do
        UCL.load("a = 1\na = 2\na = 3", default_flags).should eq({"a" => [1, 2, 3]})
      end

      it "keeps repeated object keys as an array (no silent merge/loss)" do
        result = UCL.load("s { x = 1 }\ns { y = 2 }", default_flags)
        result.should eq({"s" => [{"x" => 1}, {"y" => 2}]})
      end

      it "behaves the same under the library default flags" do
        UCL.load("s { x = 1 }\ns { y = 2 }").should eq({"s" => [{"x" => 1}, {"y" => 2}]})
      end
    end
  end

  describe ".load_file" do
    it "loads and decodes a UCL file from disk" do
      path = File.tempname("ucl", ".conf")
      File.write(path, %(name = "app"\nport = 8080\n))
      begin
        UCL.load_file(path).should eq({"name" => "app", "port" => 8080})
      ensure
        File.delete(path)
      end
    end

    it "raises DecoderError on a missing file" do
      expect_raises(UCL::Error::DecoderError) do
        UCL.load_file("/nonexistent/path/to/nowhere.conf")
      end
    end
  end

  describe ".dump" do
    it "emits the full msgpack payload even when it contains NUL bytes" do
      # [0, 42] -> msgpack: 0x92 (array2) 0x00 (int 0) 0x2a (int 42).
      UCL.dump([0, 42], "msgpack").to_slice.to_a.should eq([0x92, 0x00, 0x2a])
    end

    it "keeps sub-second precision when encoding a Time::Span" do
      UCL.dump({"t" => 1500.milliseconds}, "json").should contain("1.5")
      UCL.dump({"t" => 500.milliseconds}, "json").should contain("0.5")
    end

    context "emitter selection" do
      it "accepts a typed UCL::Emitter and matches the string form" do
        obj = {"foo" => "bar"}
        UCL.dump(obj, UCL::Emitter::Json).should eq(UCL.dump(obj, "json"))
      end

      it "still accepts the legacy string form" do
        UCL.dump({"foo" => "bar"}).should eq("foo = \"bar\";\n")
      end

      it "defaults to the config emitter" do
        UCL.dump({"foo" => "bar"}, UCL::Emitter::Config).should eq("foo = \"bar\";\n")
      end
    end
  end

  describe "round-trip" do
    it "survives a dump/load cycle (config)" do
      original = {
        "name"    => "app",
        "port"    => 8080_i64,
        "debug"   => true,
        "ratio"   => 0.5,
        "tags"    => ["a", "b"],
        "nested"  => {"deep" => {"deeper" => "x"}},
        "missing" => nil,
      }
      UCL.load(UCL.dump(original)).should eq(original)
    end
  end

  describe ".validate / .valid?" do
    it "reconstructs a clean, exact schema error message" do
      schema = File.read("spec/fixtures/validation_schema.json")
      data = File.read("spec/fixtures/validation_data_invalid.json")

      ex = expect_raises(UCL::Error::SchemaError) do
        UCL.validate(schema, data)
      end

      msg = ex.message.to_s
      msg.should eq("Invalid type of null, expected string")
      msg.valid_encoding?.should be_true
    end

    it "exposes the schema error code for programmatic handling" do
      schema = File.read("spec/fixtures/validation_schema.json")
      data = File.read("spec/fixtures/validation_data_invalid.json")

      ex = expect_raises(UCL::Error::SchemaError) do
        UCL.validate(schema, data)
      end

      ex.code.should eq(UCL::LibUCL::SchemaErrorCode::UCL_SCHEMA_TYPE_MISMATCH)
    end

    it "returns false (not raises) when the data is unparseable" do
      schema = File.read("spec/fixtures/validation_schema.json")
      UCL.valid?(schema, %(this is : : not valid ] [ ucl)).should be_false
    end

    it "returns false (not raises) when the schema is unparseable" do
      UCL.valid?(%(broken ] [ schema), %({"a": 1})).should be_false
    end

    context "with parser flags" do
      schema = %({"type": "object", "required": ["foo"], "properties": {"foo": {"type": "string"}}})
      lowercase = UCL::LibUCL::ParserFlags::UCL_PARSER_KEY_LOWERCASE

      it "threads flags through parsing (KEY_LOWERCASE makes FOO match foo)" do
        UCL.valid?(schema, %(FOO = "bar")).should be_false
        UCL.valid?(schema, %(FOO = "bar"), lowercase).should be_true
      end

      it "validate accepts flags too" do
        UCL.validate(schema, %(FOO = "bar"), lowercase).should be_true
      end
    end
  end

  describe "memory management" do
    # A use-after-free or double-free in the native free()/unref() calls would
    # corrupt the heap and crash within a tight loop.
    it "stays stable over many load/dump/validate cycles" do
      schema = File.read("spec/fixtures/validation_schema.json")
      valid = File.read("spec/fixtures/validation_data_valid.json")

      2000.times do
        decoded = UCL.load(%(a = 1\nb = "x"\nc = [1, 2, 3]))
        UCL.dump(decoded, "json")
        UCL.dump(decoded, "msgpack")
        UCL.valid?(schema, valid)
      end

      UCL.load("k = v").should eq({"k" => "v"})
    end
  end
end
