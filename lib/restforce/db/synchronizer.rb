module Restforce

  module DB

    # Restforce::DB::Synchronizer is responsible for synchronizing the records
    # in Salesforce with the records in the database. It relies on the mappings
    # configured in instances of Restforce::DB::RecordTypes::Base to create and
    # update records with the appropriate values.
    class Synchronizer

      # Public: Initialize a new Restforce::DB::Synchronizer.
      #
      # database_record_type   - A Restforce::DB::RecordTypes::ActiveRecord
      #                          instance.
      # salesforce_record_type - A Restforce::DB::RecordTypes::Salesforce
      #                          instance.
      def initialize(database_record_type, salesforce_record_type)
        @database_record_type = database_record_type
        @salesforce_record_type = salesforce_record_type
      end

      # Public: Run the synchronize process, pulling in records from Salesforce
      # and the database to determine which records need to be created and/or
      # updated.
      #
      # options - A Hash of options for configuring the run. Currently unused.
      #
      # Returns nothing.
      def run(_options = {})
        @salesforce_record_type.each do |record|
          @database_record_type.sync!(record)
        end
      end

    end

  end

end
