require "../spec_helper"

describe UCL::Validator do
  describe ".validate" do
    context "when input data are valid" do
      it "returns true" do
        schema = File.read("spec/fixtures/validation_schema.json")
        data = File.read("spec/fixtures/validation_data_valid.json")
        UCL::Validator.validate(schema, data).should eq(true)
      end
    end

    context "when input data are invalid" do
      it "raises an error" do
        schema = File.read("spec/fixtures/validation_schema.json")
        data = File.read("spec/fixtures/validation_data_invalid.json")
        expect_raises(UCL::Error::SchemaError) do
          UCL::Validator.validate(schema, data)
        end
      end
    end
  end
end
