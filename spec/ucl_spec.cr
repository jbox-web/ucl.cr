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

  describe ".validate" do
    context "when input data are valid" do
      it "returns true" do
        schema = File.read("spec/fixtures/validation_schema.json")
        data = File.read("spec/fixtures/validation_data_valid.json")
        UCL.validate(schema, data).should eq(true)
      end
    end

    context "when input data are invalid" do
      it "raises an error" do
        schema = File.read("spec/fixtures/validation_schema.json")
        data = File.read("spec/fixtures/validation_data_invalid.json")
        expect_raises(UCL::Error::SchemaError) do
          UCL.validate(schema, data)
        end
      end
    end
  end

  describe ".valid?" do
    context "when input data are valid" do
      it "returns true" do
        schema = File.read("spec/fixtures/validation_schema.json")
        data = File.read("spec/fixtures/validation_data_valid.json")
        UCL.valid?(schema, data).should eq(true)
      end
    end

    context "when input data are invalid" do
      it "returns false" do
        schema = File.read("spec/fixtures/validation_schema.json")
        data = File.read("spec/fixtures/validation_data_invalid.json")
        UCL.valid?(schema, data).should eq(false)
      end
    end
  end
end
