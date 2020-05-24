require "./spec_helper"

describe UCL do
  describe ".load" do
    it "can decode UCL data with .load" do
      UCL.load("foo = bar").should eq({"foo" => "bar"})
    end
  end

  describe ".dump" do
    it "can encode UCL data with .dump" do
      UCL.dump({"foo" => "bar"}).should eq("foo = \"bar\";\n")
    end
  end
end
