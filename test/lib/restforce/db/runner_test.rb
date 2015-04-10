require_relative "../../../test_helper"

describe Restforce::DB::Runner do
  let(:runner) { Restforce::DB::Runner.new }

  describe "#initialize" do
    before { Restforce::DB.last_run = Time.now }

    it "prefills the Collector's last_run timestamp with the global configuration" do
      expect(runner.last_run).to_equal Restforce::DB.last_run
    end
  end

  describe "#tick!" do
    before { Restforce::DB.last_run = Time.now }

    it "updates the run timestamps" do
      prior_run = runner.last_run
      new_run   = runner.tick!

      expect(runner.last_run).to_equal new_run
      expect(runner.before).to_equal new_run
      expect(runner.after).to_equal prior_run
    end

    describe "with a configured delay" do
      let(:delay) { 5 }
      let(:runner) { Restforce::DB::Runner.new(delay) }

      it "offsets the timestamps" do
        prior_run = runner.last_run
        new_run   = runner.tick!

        expect(runner.before).to_equal new_run - delay
        expect(runner.after).to_equal prior_run - delay
      end
    end
  end
end
