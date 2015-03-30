module Restforce

  module DB

    module RecordTypes

      # Restforce::DB::RecordTypes::ActiveRecord serves as a wrapper for a
      # single ActiveRecord::Base-compatible class, allowing for standard record
      # lookups and attribute mappings.
      class ActiveRecord < Base

        # Public: Create an instance of this ActiveRecord model for the passed
        # Salesforce instance.
        #
        # from_record - A Restforce::DB::Instances::Salesforce instance.
        #
        # Returns a Restforce::DB::Instances::ActiveRecord instance.
        # Raises on any validation or database error.
        def create!(from_record)
          attributes = @mapping.convert(@record_type, from_record.attributes)

          record = @record_type.new(attributes.merge(salesforce_id: from_record.id))
          associations = @mapping.associations.map do |association, lookup|
            associated = record.association(association).build
            lookup_id = from_record.record.send(lookup)
            build_association associated, lookup_id
          end

          record.transaction do
            record.save!

            # We touch the synchronization timestamps here to ensure that they
            # exceed the last updated timestamp.
            associations.each { |association| association.touch(:synchronized_at) }
          end

          Instances::ActiveRecord.new(@record_type, record, @mapping).after_sync
        end

        # Public: Find the instance of this ActiveRecord model corresponding to
        # the passed salesforce_id.
        #
        # salesforce_id - The id of the record in Salesforce.
        #
        # Returns nil or a Restforce::DB::Instances::ActiveRecord instance.
        def find(id)
          record = @record_type.find_by(salesforce_id: id)
          return nil unless record

          Instances::ActiveRecord.new(@record_type, record, @mapping)
        end

        # Public: Iterate through all recently-updated ActiveRecord records of
        # this type.
        #
        # options - A Hash of options which should be applied to the set of
        #           fetched records. Allowed options are:
        #           :before - A Time object defining the most recent update
        #                     timestamp for which records should be returned.
        #           :after  - A Time object defining the least recent update
        #                     timestamp for which records should be returned.
        #
        # Yields a series of Restforce::DB::Instances::ActiveRecord instances.
        # Returns nothing.
        def each(options = {})
          scope = @record_type.where("updated_at > synchronized_at OR synchronized_at IS NULL")
          scope = scope.where("updated_at > ?", options[:after]) if options[:after]
          scope = scope.where("updated_at < ?", options[:before]) if options[:before]

          scope.find_each do |record|
            yield Instances::ActiveRecord.new(@record_type, record, @mapping)
          end
        end

        private

        # Internal: Has this Salesforce record already been linked to a database
        # record of this type?
        #
        # record - A Restforce::DB::Instances::Salesforce instance.
        #
        # Returns a Boolean.
        def synced?(record)
          @record_type.exists?(salesforce_id: record.id)
        end

        # Internal: Assemble an associated record, using the data from the
        # Salesforce record corresponding to a specific lookup ID.
        #
        # TODO: With some refactoring using ActiveRecord inflections, this
        # should be possible to handle as a recursive call to the configured
        # Mapping's database record type. Right now, nested associations are
        # ignored.
        #
        # associated - The associated database record.
        # lookup_id  - A Salesforce ID corresponding to the record type in the
        #              Mapping defined for the associated database model.
        #
        # Returns the associated ActiveRecord instance.
        def build_association(associated, lookup_id)
          return if lookup_id.nil?

          mapping = Mapping[associated.class]

          salesforce_instance = mapping.salesforce_record_type.find(lookup_id)
          attributes = mapping.convert(associated.class, salesforce_instance.attributes)

          associated.assign_attributes(attributes.merge(salesforce_id: lookup_id))
          associated
        end

      end

    end

  end

end
