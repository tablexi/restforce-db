module Restforce

  module DB

    module Associations

      # Restforce::DB::Associations::HasOne defines a relationship in which a
      # Salesforce ID for this Mapping's database record exists on the named
      # database association's Mapping.
      class HasOne < Base

        include ForeignKey

        # Public: Construct a database record from a single Salesforce record
        # associated with the supplied parent Salesforce record.
        #
        # database_record   - An instance of an ActiveRecord::Base subclass.
        # salesforce_record - A Hashie::Mash representing a Salesforce object.
        #
        # Returns the constructed association record.
        def build(database_record, salesforce_record)
          target = target_mapping(database_record)
          lookup_id = "#{lookup_field(target, database_record)} = '#{salesforce_record.Id}'"

          target.salesforce_record_type.each(conditions: lookup_id) do |instance|
            break construct_for(database_record, instance)
          end
        end

      end

    end

  end

end
