module Restforce

  module DB

    # Restforce::DB::FieldProcessor encapsulates logic for preventing
    # information for unwriteable fields from being submitted to Salesforce.
    class FieldProcessor

      # Internal: Get a global cache with which to store/fetch the writable
      # fields for each Salesforce SObject Type.
      #
      # Returns a Hash.
      def self.field_cache
        @field_cache ||= {}
      end

      # Internal: Clear out the global field cache.
      #
      # Returns nothing.
      def self.reset
        @field_cache = {}
      end

      # Public: Get a restricted version of the passed attributes Hash, with
      # unwritable fields stripped out.
      #
      # sobject_type - A String name of an SObject Type in Salesforce.
      # attributes   - A Hash with keys corresponding to Salesforce field names.
      #
      # Returns a Hash.
      def process(sobject_type, attributes)
        attributes.each_with_object({}) do |(field, value), processed|
          next unless writable?(sobject_type, field)
          processed[field] = value
        end
      end

      private

      # Internal: Is the passed attribute writable for the passed SObject Type?
      #
      # sobject_type - A String name of an SObject Type in Salesforce.
      # field        - A String Salesforce field API name.
      #
      # Returns a Boolean.
      def writable?(sobject_type, field)
        field_statuses(sobject_type)[field]
      end

      # Internal: Get a collection of all fields for the passed Salesforce
      # SObject Type, with an indication of whether or not they are writable.
      #
      # sobject_type - A String name of an SObject Type in Salesforce.
      #
      # Returns a Hash.
      def field_statuses(sobject_type)
        self.class.field_cache[sobject_type] ||= begin
          fields = Restforce::DB.client.describe(sobject_type).fields

          fields.each_with_object({}) do |field, output|
            output[field["name"]] = field["updateable"]
          end
        end
      end

    end

  end

end
