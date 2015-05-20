module Restforce

  module DB

    # Restforce::DB::Client is a thin abstraction on top of the default
    # Restforce::Data::Client class, which adds support for a handful of useful
    # endpoints not yet supported by the base gem.
    class Client < ::Restforce::Data::Client

      # Public: Get a list of Salesforce records which have been deleted between
      # the specified times.
      #
      # sobject    - The Salesforce object type to query against.
      # start_time - A Time or Time-compatible object indicating the earliest
      #              time for which to find deleted records.
      # end_time   - A Time or Time-compatible object indicating the latest time
      #              for which to find deleted records. Defaults to the current
      #              time.
      #
      # Example
      #
      #   Restforce::DB.client.get_deleted_between(
      #     "CustomObject__c",
      #     Time.now - 300,
      #     Time.now,
      #   )
      #
      #   #=> #<Restforce::Mash
      #          latestDateCovered="2015-05-18T22:31:00.000+0000"
      #          earliestDateAvailable="2015-04-11T06:44:00.000+0000"
      #          deletedRecords=[
      #            #<Restforce::Mash
      #              deletedDate="2015-05-18T22:31:17.000+0000"
      #              id="a001a000001a5vOAAQ"
      #            >
      #          ]
      #        >
      #
      # Returns a Restforce::Mash with a `deletedRecords` key.
      def get_deleted_between(sobject, start_time, end_time = Time.now)
        api_get(
          "sobjects/#{sobject}/deleted",
          start: start_time.utc.iso8601,
          end: end_time.utc.iso8601,
        ).body
      end

    end

  end

end
