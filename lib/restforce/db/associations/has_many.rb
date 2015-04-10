module Restforce

  module DB

    module Associations

      # Restforce::DB::Associations::HasMany defines a relationship in which
      # potentially several Salesforce records maintain a reference to the
      # Salesforce record on the current Mapping.
      class HasMany < Base

        include ForeignKey

        # Public: Construct a database record for each Salesforce record
        # associated with the supplied parent Salesforce record.
        #
        # database_record   - An instance of an ActiveRecord::Base subclass.
        # salesforce_record - A Hashie::Mash representing a Salesforce object.
        #
        # Returns the constructed association records.
        def build(database_record, salesforce_record)
          target = target_mapping(database_record)
          lookup_id = "#{lookup_field(target, database_record)} = '#{salesforce_record.Id}'"

          records = []
          target.salesforce_record_type.each(conditions: lookup_id) do |instance|
            records << construct_for(database_record, instance)
          end

          records
        end

      end

    end

  end

end
