require "../spec_helper"

describe "#to_ucl" do
  it "encodes a Hash in config format by default" do
    {"foo" => "bar"}.to_ucl.should eq(%(foo = "bar";\n))
  end

  it "forwards a String emitter to the encoder" do
    {"foo" => "bar"}.to_ucl("json").should eq(UCL.dump({"foo" => "bar"}, "json"))
  end

  it "forwards a typed UCL::Emitter to the encoder" do
    {"foo" => "bar"}.to_ucl(UCL::Emitter::Json).should eq(UCL.dump({"foo" => "bar"}, UCL::Emitter::Json))
  end

  it "encodes an Array" do
    [1, 2, 3].to_ucl.should eq(UCL.dump([1, 2, 3]))
  end

  it "encodes a nested structure" do
    obj = {"a" => [1, 2], "b" => {"c" => true}}
    obj.to_ucl.should eq(UCL.dump(obj))
  end

  it "encodes scalars matching the encoder" do
    "hello".to_ucl.should eq(UCL.dump("hello"))
    42.to_ucl.should eq(UCL.dump(42))
    3.14.to_ucl.should eq(UCL.dump(3.14))
    true.to_ucl.should eq(UCL.dump(true))
    nil.to_ucl.should eq(UCL.dump(nil))
    10.seconds.to_ucl.should eq(UCL.dump(10.seconds))
  end

  context "NamedTuple" do
    it "encodes via to_ucl, default and typed emitter" do
      {port: 8080, host: "localhost"}.to_ucl
        .should eq(UCL.dump({"port" => 8080, "host" => "localhost"}))
      {port: 8080}.to_ucl(UCL::Emitter::Json).should eq(UCL.dump({"port" => 8080}, UCL::Emitter::Json))
    end
  end

  context "UCL::Value" do
    it "encodes via to_ucl" do
      v = UCL::Value.new
      v["foo"] = "bar"
      v.to_ucl.should eq(%(foo = "bar";\n))
      v.to_ucl("json").should eq(UCL.dump({"foo" => "bar"}, "json"))
    end
  end

  context "UCL::Any" do
    it "encodes via to_ucl" do
      any = UCL.load_any(%(foo = "bar";))
      any.to_ucl.should eq(%(foo = "bar";\n))
      any.to_ucl("json").should eq(UCL.dump({"foo" => "bar"}, "json"))
    end
  end
end
