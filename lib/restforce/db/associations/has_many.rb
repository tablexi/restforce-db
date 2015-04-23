module Restforce

  module DB

    module Associations

      # Restforce::DB::Associations::HasMany defines a relationship in which
      # potentially several Salesforce records maintain a reference to the
      # Salesforce record on the current Mapping.
      class HasMany < ForeignKey

        # Public: Construct a database record for each Salesforce record
        # associated with the supplied parent Salesforce record.
        #
        # database_record   - An instance of an ActiveRecord::Base subclass.
        # salesforce_record - A Hashie::Mash representing a Salesforce object.
        #
        # Returns an Array of constructed association records.
        def build(database_record, salesforce_record)
          target = target_mapping(database_record)
          lookup_id = "#{lookup_field(target, database_record)} = '#{salesforce_record.Id}'"

          records = []
          target.salesforce_record_type.each(conditions: lookup_id) do |instance|
            records << construct_for(database_record, instance)
          end

          records.flatten
        end

        private

        # Internal: Get the method by which an associated record should be
        # assigned to this record. Replaces :writer with :concat, which appends
        # records to an existing association, rather than replacing it.
        #
        # Returns a Symbol.
        def construction_method
          :concat
        end

      end

    end

  end

end
