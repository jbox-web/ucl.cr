require "../spec_helper"

describe UCL::Value do
  describe "hash-like access" do
    it "sets and gets values" do
      v = UCL::Value.new
      v["a"] = "b"
      v["a"].should eq("b")
    end

    it "returns nil for a missing key with #[]?" do
      v = UCL::Value.new
      v["missing"]?.should be_nil
    end

    it "raises for a missing key with #[]" do
      v = UCL::Value.new
      expect_raises(KeyError) { v["missing"] }
    end

    it "deletes a key" do
      v = UCL::Value.new
      v["a"] = 1_i64
      v.delete("a")
      v["a"]?.should be_nil
    end

    it "exposes the underlying hash via #raw and #to_h" do
      v = UCL::Value.new
      v["a"] = 1_i64
      v.raw.should eq({"a" => 1_i64})
      v.to_h.should eq({"a" => 1_i64})
    end

    it "iterates entries with #each" do
      v = UCL::Value.new
      v["a"] = 1_i64
      collected = {} of String => UCL::Value::Type
      v.each { |k, val| collected[k] = val }
      collected.should eq({"a" => 1_i64})
    end
  end

  describe "serialization (API1 - json/yaml must be required)" do
    it "serializes to JSON" do
      v = UCL::Value.new
      v["a"] = "b"
      v.to_json.should eq(%({"a":"b"}))
    end

    it "serializes to YAML" do
      v = UCL::Value.new
      v["a"] = "b"
      v.to_yaml.should contain("a: b")
    end
  end
end
