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

    end

  end

end
