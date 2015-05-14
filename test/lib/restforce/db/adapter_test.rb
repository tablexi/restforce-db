require_relative "../../../test_helper"

describe Restforce::DB::Adapter do

  configure!

  let(:adapter) { Restforce::DB::Adapter.new }
  let(:attributes) { { where: "Here", when: Time.now } }

  describe "#to_database" do
    let(:results) { adapter.to_database(attributes) }

    it "returns the passed attributes, unchanged" do
      expect(results).to_equal attributes
    end
  end

  describe "#from_database" do
    let(:results) { adapter.from_database(attributes) }

    it "converts times to ISO-8601 timestamps" do
      expect(results[:when]).to_equal attributes[:when].utc.iso8601
    end

    it "leaves other attributes unchanged" do
      expect(results[:where]).to_equal attributes[:where]
    end
  end
end
