module Restforce

  module DB

    # Restforce::DB::FieldProcessor encapsulates logic for preventing
    # information for unwriteable fields from being submitted to Salesforce.
    class FieldProcessor

      # This token indicates that a relationship is being accessed for a
      # specific field.
      RELATIONSHIP_MATCHER = /(.+)__r\./.freeze

      class << self

        # Public: Fetch the field metadata for all Salesforce models registered
        # through mappings in the system. Useful to ensure that forked worker
        # processes have access to all of the field metadata without the need
        # for additional querying.
        #
        # Returns nothing.
        def preload
          Registry.each { |mapping| fetch(mapping.salesforce_model) }
        end

        # Public: Get a global cache with which to store/fetch the field
        # metadata for each Salesforce Object Type.
        #
        # Returns a Hash.
        def field_cache
          @field_cache ||= {}
        end

        # Public: Get a collection of all fields for the passed Salesforce
        # Object Type, with an indication of whether or not they are readable
        # and writable for both create and update actions.
        #
        # sobject_type - A String name of an Object Type in Salesforce.
        #
        # Returns a Hash.
        def fetch(sobject_type)
          field_cache[sobject_type] ||= begin
            fields = DB.client.describe(sobject_type).fields

            fields.each_with_object({}) do |field, permissions|
              permissions[field["name"]] = {
                read:   true,
                create: field["createable"],
                update: field["updateable"],
              }
            end
          end
        end

        # Public: Clear out the global field cache.
        #
        # Returns nothing.
        def reset
          @field_cache = {}
        end

      end

      # Public: Get a list of valid fields for a specific action from the passed
      # list of proposed fields. Allows access to related object fields on a
      # read-only basis.
      #
      # sobject_type - A String name of an SObject Type in Salesforce.
      # attributes   - A Hash with keys corresponding to Salesforce field names.
      # action       - A Symbol reflecting the action to perform. Accepted
      #                values are :read, :create, and :update.
      #
      # Returns a Hash.
      def available_fields(sobject_type, fields, action = :read)
        fields.select do |field|
          known_field = available?(sobject_type, field, action)
          relationship = action == :read && relationship?(field)

          known_field || relationship
        end
      end

      # Public: Get a restricted version of the passed attributes Hash, with
      # inaccessible fields for the specified action stripped out.
      #
      # sobject_type - A String name of an SObject Type in Salesforce.
      # attributes   - A Hash with keys corresponding to Salesforce field names.
      # action       - A Symbol reflecting the action to perform. Accepted
      #                values are :create and :update.
      #
      # Returns a Hash.
      def process(sobject_type, attributes, action)
        attributes.select { |field, _| available?(sobject_type, field, action) }
      end

      private

      # Internal: Is the passed attribute available for the specified action on
      # the passed SObject Type?
      #
      # sobject_type - A String name of an SObject Type in Salesforce.
      # field        - A String Salesforce field API name.
      # action       - A Symbol reflecting the requested action. Accepted values
      #                are :read, :create, and :update.
      #
      # Returns a Boolean.
      def available?(sobject_type, field, action)
        permissions = self.class.fetch(sobject_type)[field]
        return false unless permissions

        permissions[action]
      end

      # Internal: Does the passed field description reference an attribute
      # through an associated object?
      #
      # NOTE: It's not worth the trouble to validate that this relationship
      # actually exists, or that the requested field exists on the related
      # model. If a bad lookup is specified, the API will throw an error.
      #
      # field - A String Salesforce field API name.
      #
      # Rturns a Boolean.
      def relationship?(field)
        field =~ RELATIONSHIP_MATCHER
      end

    end

  end

end
