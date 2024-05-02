require "../spec_helper"

INPUT_OBJECT =
  {
    "string"  => "bar",
    "true"    => true,
    "false"   => false,
    "nil"     => nil,
    "integer" => 1864,
    "double"  => 23.42,
    "time"    => 10.seconds,
    "array"   => [
      "foo",
      true,
      false,
      nil,
      1864,
      23.42,
      10.seconds,
    ],
    "hash" => {
      "foo" => "bar",
      "bar" => "baz",
      "baz" => "foo",
    },
    "array_of_array" => [
      ["foo", "bar"],
      ["bar", "baz"],
    ],
    "section" => {
      "foo" => {
        "key" => "value",
      },
      "bar" => {
        "key" => "value",
      },
      "baz" => {
        "foo" => {
          "key" => "value",
        },
      },
    },
  }

describe UCL::Encoder do
  describe ".encode" do
    context "when emit_type is config" do
      it "should encode UCL conf" do
        output_ucl_conf = File.read("spec/fixtures/output_ucl.conf")
        UCL::Encoder.encode(INPUT_OBJECT).should eq(output_ucl_conf)
        UCL::Encoder.encode(INPUT_OBJECT, "config").should eq(output_ucl_conf)
      end
    end

    context "when emit_type is yaml" do
      it "should encode UCL conf" do
        output_ucl_conf = File.read("spec/fixtures/output_ucl.yml")
        UCL::Encoder.encode(INPUT_OBJECT, "yaml").should eq(output_ucl_conf.chomp)
      end
    end

    context "when emit_type is json" do
      it "should encode UCL conf" do
        output_ucl_conf = File.read("spec/fixtures/output_ucl.json")
        UCL::Encoder.encode(INPUT_OBJECT, "json").should eq(output_ucl_conf.chomp)
      end
    end

    context "when emit_type is json_compact" do
      it "should encode UCL conf" do
        output_ucl_conf = File.read("spec/fixtures/output_ucl.json.min")
        UCL::Encoder.encode(INPUT_OBJECT, "json_compact").should eq(output_ucl_conf.chomp)
      end
    end

    context "when emit_type is msgpack" do
      it "should encode UCL conf" do
        output_ucl_conf = File.read("spec/fixtures/output_ucl.msgpack")
        UCL::Encoder.encode(INPUT_OBJECT, "msgpack").should eq(output_ucl_conf.chomp)
      end
    end

    context "when emit_type is unknown" do
      it "should raise error" do
        expect_raises(UCL::Error::EncoderError) do
          UCL::Encoder.encode(INPUT_OBJECT, "foo")
        end
      end
    end

    context "when key object is not serializable" do
      it "raises an error" do
        input_object = {} of Foo => String
        input_object[Foo.new] = "foo"

        expect_raises(UCL::Error::TypeError) do
          UCL::Encoder.encode(input_object)
        end
      end
    end

    context "when value object is not serializable" do
      it "raises an error" do
        input_object = {} of String => Foo
        input_object["foo"] = Foo.new

        expect_raises(UCL::Error::TypeError) do
          UCL::Encoder.encode(input_object)
        end
      end
    end
  end
end
