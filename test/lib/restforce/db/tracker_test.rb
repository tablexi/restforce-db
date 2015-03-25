require_relative "../../../test_helper"

describe Restforce::DB::Tracker do
  let(:file) { Tempfile.new(".restforce-db") }
  let(:tracker) { Restforce::DB::Tracker.new(file.path) }
  let(:runtime) { Time.now }

  describe "#initialize" do
    after { Restforce::DB.last_run = nil }

    describe "when no timestamp has been recorded" do

      it "does not initialize Restforce::DB.last_run" do
        expect(Restforce::DB.last_run).to_be_nil
      end
    end

    describe "when a timestamp has been recorded in the file" do
      before do
        file.print runtime.iso8601
        file.rewind
      end

      it "initializes Restforce::DB.last_run to the value" do
        tracker
        expect(Restforce::DB.last_run.to_i).to_equal runtime.to_i
      end
    end
  end

end
