module Restforce

  module DB

    # Restforce::DB::Model is a helper module which attaches some special
    # DSL-style methods to an ActiveRecord class, allowing for easier mapping
    # of the ActiveRecord class to an object type in Salesforce.
    module Model

      # :nodoc:
      def self.included(base)
        base.extend(ClassMethods)
      end

      # :nodoc:
      module ClassMethods

        # Public: Initializes a Restforce::DB::Mapping defining this model's
        # relationship to a Salesforce object type. Passes a provided block to
        # the Restforce::DB::DSL for evaluation.
        #
        # salesforce_model - A String name of an object type in Salesforce.
        # strategy         - A Symbol naming a desired initialization strategy.
        # options          - A Hash of options to pass through to the Mapping.
        # block            - A block of code to evaluate through the DSL.
        #
        # Returns nothing.
        def sync_with(salesforce_model, strategy = :always, options = {}, &block)
          Restforce::DB::DSL.new(self, salesforce_model, strategy, options).instance_eval(&block)
        end

      end

      # Public: Force a synchronization to run for this specific record. If the
      # record has not yet been pushed up to Salesforce, create it. In the event
      # that the record has already been synchronized, force the data to be re-
      # synchronized.
      #
      # NOTE: To ensure that we aren't attempting to synchronize data which has
      # not actually been committed to the database, this method no-ops for
      # unpersisted records, and discards all local changes to the record prior
      # to syncing.
      #
      # Returns a Boolean.
      def force_sync!
        return false unless persisted?
        reload

        sync_instances.each do |instance|
          salesforce_record_type = instance.mapping.salesforce_record_type

          if instance.synced?
            salesforce_instance = salesforce_record_type.find(instance.id)
            next unless salesforce_instance

            accumulator = Restforce::DB::Accumulator.new
            accumulator.store(instance.last_update, instance.attributes)
            accumulator.store(salesforce_instance.last_update, salesforce_instance.attributes)

            synchronizer = Restforce::DB::Synchronizer.new(instance.mapping)
            synchronizer.update(instance, accumulator)
            synchronizer.update(salesforce_instance, accumulator)
          else
            salesforce_record_type.create!(instance)
          end
        end

        true
      end

      private

      # Internal: Get a collection of instances for each mapping set up on this
      # record's model, for use in custom synchronization code.
      #
      # Returns an Array of Restforce::DB::Instances::ActiveRecord objects.
      def sync_instances
        Restforce::DB::Registry[self.class].map do |mapping|
          Restforce::DB::Instances::ActiveRecord.new(
            mapping.database_model,
            self,
            mapping,
          )
        end
      end

    end

  end

end
