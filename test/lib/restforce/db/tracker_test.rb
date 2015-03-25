require_relative "../../../test_helper"

describe Restforce::DB::Tracker do
  let(:file) { Tempfile.new(".restforce-db") }
  let(:tracker) { Restforce::DB::Tracker.new(file.path) }
  let(:runtime) { Time.now }

  after { Restforce::DB.last_run = nil }

  describe "#initialize" do

    describe "when no timestamp has been recorded" do
      before { tracker }

      it "does not initialize Restforce::DB.last_run" do
        expect(Restforce::DB.last_run).to_be_nil
      end
    end

    describe "when a timestamp has been recorded in the file" do
      before do
        file.print runtime.iso8601
        file.rewind

        tracker
      end

      it "initializes Restforce::DB.last_run to the recorded time" do
        expect(Restforce::DB.last_run.to_i).to_equal runtime.to_i
      end

      it "initializes the tracker's last_run to the recorded time" do
        expect(tracker.last_run.to_i).to_equal runtime.to_i
      end
    end
  end

  describe "#track" do
    before { tracker.track runtime }

    it "records the supplied timestamp in the file" do
      expect(file.read).to_equal runtime.iso8601
    end

    it "updates the tracker's last_run to the recorded time" do
      expect(tracker.last_run.to_i).to_equal runtime.to_i
    end
  end

end
