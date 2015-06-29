require_relative "../../../test_helper"

describe Restforce::DB::Worker do

  configure!
  mappings!

  let(:worker) { Restforce::DB::Worker.new(delay: 0) }
  let(:runner) { worker.send(:runner) }

  describe "a race condition during synchronization", vcr: { match_requests_on: [:method, VCR.request_matchers.uri_without_param(:q)] } do
    let(:database_record) { mapping.database_model.create! }
    let(:new_name) { "A New User-Entered Name" }

    before do
      # 0. A record is added to the database.
      database_record

      # 1. The first loop runs

      ## 1b. The record is synced to Salesforce.
      worker.send :reset!
      worker.send :task, Restforce::DB::Initializer, mapping

      expect(database_record.reload).to_be :salesforce_id?
      Salesforce.records << [salesforce_model, database_record.salesforce_id]

      ## 1c. The database record is updated (externally) by a user.
      database_record.update! name: new_name

      # We stub `last_update` to get around issues with VCR's cached timestamp;
      # we need the Salesforce record timestamp to be contemporary with this
      # test run.
      Restforce::DB::Instances::Salesforce.stub_any_instance(:last_update, Time.now) do

        ## 1d. The record in Salesforce is touched by another mapping.
        salesforce_instance = mapping.salesforce_record_type.find(
          database_record.salesforce_id,
        )
        salesforce_instance.update! "Name" => "A Stale Synchronized Name"
        runner.cache_timestamp salesforce_instance

        # 2. The second loop runs.
        # We sleep here to ensure we pick up our manual changes.
        sleep 1 if VCR.current_cassette.recording?
        worker.send :reset!
        worker.send :task, Restforce::DB::Collector, mapping
        worker.send :task, Restforce::DB::Synchronizer, mapping
      end
    end

    it "does not change the user-entered name on the database record" do
      expect(database_record.reload.name).to_equal new_name
    end

    it "overrides the stale-but-more-recent name on the Salesforce" do
      salesforce_instance = mapping.salesforce_record_type.find(
        database_record.salesforce_id,
      )

      expect(salesforce_instance.record.Name).to_equal new_name
    end
  end
end
