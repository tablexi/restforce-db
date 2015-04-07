module Restforce

  module DB

    # Restforce::DB::Synchronizer is responsible for synchronizing the records
    # in Salesforce with the records in the database. It relies on the mappings
    # configured in instances of Restforce::DB::RecordTypes::Base to create and
    # update records with the appropriate values.
    class Synchronizer

      # Public: Initialize a new Restforce::DB::Synchronizer.
      #
      # mapping - A Restforce::DB::Mapping.
      def initialize(mapping)
        @mapping = mapping
      end

      # Public: Synchronize records for the current mapping from a Hash of
      # record descriptors to attributes.
      #
      # changes - A Hash, with keys composed of a Salesforce ID and model name,
      #           with Restforce::DB::Accumulator objects as values.
      #
      # Returns nothing.
      def run(changes)
        changes.each do |(id, salesforce_model), accumulator|
          next unless salesforce_model == @mapping.salesforce_model

          update(@mapping.database_record_type.find(id), accumulator)
          update(@mapping.salesforce_record_type.find(id), accumulator)
        end
      end

      private

      # Internal: Update the passed instance with the accumulated attributes
      # from a synchronization run.
      #
      # instance    - An instance of Restforce::DB::Instances::Base.
      # accumulator - A Restforce::DB::Accumulator.
      #
      # Returns nothing.
      def update(instance, accumulator)
        diff = accumulator.diff(@mapping.convert(@mapping.salesforce_model, instance.attributes))
        attributes = @mapping.convert_from_salesforce(instance.record_type, diff)

        return if attributes.empty?
        instance.update!(attributes)
      end

    end

  end

end
