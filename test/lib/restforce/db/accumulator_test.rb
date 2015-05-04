require_relative "../../../test_helper"

describe Restforce::DB::Accumulator do

  configure!

  let(:accumulator) { Restforce::DB::Accumulator.new }

  describe "#store" do
    let(:timestamp) { Time.now }
    let(:changes) { { one_fish: "Two Fish", red_fish: "Blue Fish" } }

    before do
      accumulator.store(timestamp, changes)
    end

    it "stores the passed changeset in the accumulator" do
      expect(accumulator[timestamp]).to_equal changes
    end

    describe "for a pre-existing timestamp" do
      let(:new_changes) { { old_fish: "New Fish" } }

      before do
        accumulator.store(timestamp, new_changes)
      end

      it "updates the existing changeset in the accumulator" do
        expect(accumulator[timestamp]).to_equal changes.merge(new_changes)
      end
    end
  end

  describe "#attributes" do
    let(:timestamp) { Time.now }
    let(:changes) { { one_fish: "Two Fish", red_fish: "Blue Fish" } }

    before do
      accumulator.store(timestamp, changes)
    end

    it "returns the attributes from the recorded changeset" do
      expect(accumulator.attributes).to_equal changes
    end

    it "combines multiple changesets" do
      additional_changes = { hootie: "Blow Fish" }

      accumulator.store Time.now, additional_changes
      expect(accumulator.attributes).to_equal changes.merge(additional_changes)
    end

    describe "with conflicting changesets" do
      let(:new_changes) { { one_fish: "No Fish", red_fish: "Glow Fish" } }

      it "respects the most recently updated values" do
        accumulator.store timestamp + 1, new_changes
        expect(accumulator.attributes).to_equal new_changes
      end

      it "ignores less recently updated values" do
        accumulator.store timestamp - 1, new_changes
        expect(accumulator.attributes).to_equal changes
      end
    end
  end

  describe "#diff" do
    let(:attributes) { { wocket: "Pocket", jertain: "Curtain", zelf: "Shelf" } }

    before do
      accumulator.store(Time.now, attributes)
    end

    it "returns the differences from the attributes hash" do
      expect(accumulator.diff(wocket: "Locket", zelf: "Belfrey")).to_equal(
        wocket: "Pocket",
        zelf: "Shelf",
      )
    end

    it "ignores attributes not set in the Accumulator" do
      expect(accumulator.diff(yottle: "Bottle")).to_be :empty?
    end
  end
end
