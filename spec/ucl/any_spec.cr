require "../spec_helper"

describe UCL::Any do
  it "gives typed access without casts" do
    any = UCL.load_any(%(name = "app"\nport = 8080\nratio = 0.5\ndebug = true))
    any["name"].as_s.should eq("app")
    any["port"].as_i.should eq(8080)
    any["ratio"].as_f.should eq(0.5)
    any["debug"].as_bool.should be_true
  end

  it "navigates nested objects and arrays" do
    any = UCL.load_any("srv { hosts = [\"a\", \"b\"] }")
    any["srv"]["hosts"][0].as_s.should eq("a")
    any["srv"]["hosts"].as_a.map(&.as_s).should eq(["a", "b"])
  end

  it "returns nil from the nilable accessors on a missing key or wrong type" do
    any = UCL.load_any(%(name = "app"))
    any["missing"]?.should be_nil
    any["name"].as_i?.should be_nil
    any["name"].as_s?.should eq("app")
  end

  it "exposes the raw value and a hash view" do
    any = UCL.load_any(%(a = 1\nb = 2))
    any.as_h.transform_values(&.as_i).should eq({"a" => 1_i64, "b" => 2_i64})
    any.raw.should eq({"a" => 1_i64, "b" => 2_i64})
  end
end
