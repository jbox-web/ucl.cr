require "../spec_helper"

OUTPUT_OBJECT =
  {
    "string"  => "bar",
    "string2" => "baz",
    "true"    => true,
    "false"   => false,
    "nil"     => nil,
    "integer" => 1864,
    "double"  => 23.42,
    "time"    => "10s",
    "array"   => [
      "foo",
      true,
      false,
      nil,
      1864,
      23.42,
      "10s",
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
    "auto_array" => {
      "key" => ["foo", "bar", "baz"],
    },
    "section" => [
      {
        "foo" => {
          "key" => "value",
        },
      },
      {
        "bar" => {
          "key" => "value",
        },
      },
      {
        "baz" => {
          "foo" => {
            "key" => "value",
          },
        },
      },
    ],
    "subsection" => {
      "host" => [
        {
          "host" => "hostname",
          "port" => 900,
        },
        {
          "host" => "hostname",
          "port" => 901,
        },
      ],
    },
  }

describe UCL::Decoder do
  describe ".decode" do
    it "should decode UCL conf" do
      input_ucl_conf = File.read("spec/fixtures/input_ucl.conf")
      UCL::Decoder.decode(input_ucl_conf).should eq(OUTPUT_OBJECT)
    end

    it "should raise error on invalid UCL conf" do
      input_ucl_conf = File.read("spec/fixtures/input_ucl_invalid.conf")
      expect_raises(UCL::Error::DecoderError) do
        UCL::Decoder.decode(input_ucl_conf)
      end
    end
  end
end
