module Restforce

  module DB

    # Internal: Restforce::DB::Mapping captures a set of mappings between
    # database columns and Salesforce fields, providing utilities to transform
    # hashes of attributes from one to the other.
    class Mapping

      attr_reader :mappings

      # Public: Initialize a new Restforce::DB::Mapping.
      #
      # mappings - A Hash, with keys corresponding to the names of Ruby object
      #            attributes, and the values of those keys corresponding to the
      #            names of the related Salesforce fields.
      def initialize(mappings = {})
        @mappings = mappings
      end

      # Public: Append a new set of attribute mappings to the current set.
      #
      # mappings - A Hash, with keys corresponding to the names of Ruby object
      #            attributes, and the values of those keys corresponding to the
      #            names of the related Salesforce fields.
      #
      # Returns nothing.
      def add_mappings(mappings = {})
        @mappings.merge!(mappings)
      end

      # Public: Get a list of the relevant Salesforce field names for this
      # mapping.
      #
      # Returns an Array.
      def salesforce_fields
        @mappings.values
      end

      # Public: Get a list of the relevant database column names for this
      # mapping.
      #
      # Returns an Array.
      def database_fields
        @mappings.keys
      end

      # Public: Build a Hash of attributes in the expected format
      #
      # in_format - A Symbol reflecting the expected attribute list. Accepted
      #             values are :database and :salesforce.
      #
      # Yields the attribute name.
      # Returns a Hash.
      def attributes(in_format)
        attribute_list = send(:"#{in_format}_fields")

        attribute_list.each_with_object({}) do |attribute, values|
          values[attribute] = yield(attribute)
        end
      end

      # Public: Convert a Hash of attributes to a format compatible with a
      # specific platform.
      #
      # to_format  - A Symbol reflecting the expected format. Accepted values
      #              are :database and :salesforce.
      # attributes - A Hash, with keys corresponding to the attribute names in
      #              the format to convert away from.
      #
      # Examples
      #
      #   mapping = Mapping.new(some_key: "Some_Field__c")
      #   mapping.convert(:salesforce, some_key: "some value")
      #   # => { "Some_Field__c" => "some value" }
      #
      #   mapping.convert(:database, "Some_Field__c" => "some other value")
      #   # => { some_key: "some other value" }
      #
      # Returns a Hash.
      def convert(to_format, attributes)
        use_mappings =
          case to_format
          when :salesforce then @mappings
          when :database then @mappings.invert
          end

        use_mappings.each_with_object({}) do |(attribute, mapping), converted|
          converted[mapping] = attributes[attribute]
        end
      end

    end

  end

end
