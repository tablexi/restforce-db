module Restforce

  module DB

    module Associations

      # Restforce::DB::Associations::HasOne defines a relationship in which a
      # Salesforce ID for this Mapping's database record exists on the named
      # database association's Mapping.
      class HasOne < ForeignKey

        # Public: Construct a database record from a single Salesforce record
        # associated with the supplied parent Salesforce record.
        #
        # database_record   - An instance of an ActiveRecord::Base subclass.
        # salesforce_record - A Hashie::Mash representing a Salesforce object.
        # cache             - A Restforce::DB::AssociationCache (optional).
        #
        # Returns an Array of constructed association records.
        def build(database_record, salesforce_record, cache = AssociationCache.new(database_record))
          return [] unless build?

          @cache = cache

          target = target_mapping(database_record)
          reflection = target_reflection(database_record)
          query = "#{lookup_field(target, reflection)} = '#{salesforce_record.Id}'"

          instance = target.salesforce_record_type.first(query)
          instance ? construct_for(database_record, instance) : []
        ensure
          @cache = nil
        end

      end

    end

  end

end
