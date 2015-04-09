module Restforce

  module DB

    # Restforce::DB::AttributeMap encapsulates the logic for converting between
    # various representations of attribute hashes.
    class AttributeMap

      # Public: Initialize a Restforce::DB::AttributeMap.
      #
      # database_model   - A Class compatible with ActiveRecord::Base.
      # salesforce_model - A String name of an object type in Salesforce.
      # fields           - A Hash of mappings between database columns and
      #                    fields in Salesforce.
      def initialize(database_model, salesforce_model, fields = {})
        @database_model = database_model
        @salesforce_model = salesforce_model
        @fields = fields

        @types = {
          database_model   => :database,
          salesforce_model => :salesforce,
        }
      end

      # Public: Build a normalized Hash of attributes from the appropriate set
      # of mappings. The keys of the resulting mapping Hash will correspond to
      # the database column names.
      #
      # from_format - A String or Class reflecting the record type from which
      #               the attribute Hash is being compiled.
      #
      # Yields a series of attribute names.
      # Returns a Hash.
      def attributes(from_format)
        use_mappings =
          case @types[from_format]
          when :salesforce
            @fields
          when :database
            # Generate a mapping of database column names to record attributes.
            @fields.keys.zip(@fields.keys)
          else
            raise ArgumentError
          end

        use_mappings.each_with_object({}) do |(attribute, mapping), values|
          values[attribute] = yield(mapping)
        end
      end

      # Public: Convert a Hash of normalized attributes to a format compatible
      # with a specific platform.
      #
      # to_format  - A String or Class reflecting the record type for which the
      #              attribute Hash is being compiled.
      # attributes - A Hash of attributes, with keys corresponding to the
      #              normalized attribute names.
      #
      # Examples
      #
      #   mapping = AttributeMap.new(
      #     MyClass,
      #     "Object__c",
      #     some_key: "SomeField__c",
      #   )
      #
      #   mapping.convert("Object__c", some_key: "some value")
      #   # => { "Some_Field__c" => "some value" }
      #
      #   mapping.convert(MyClass, some_key: "some other value")
      #   # => { some_key: "some other value" }
      #
      # Returns a Hash.
      def convert(to_format, attributes)
        case @types[to_format]
        when :database
          attributes.dup
        when :salesforce
          @fields.each_with_object({}) do |(attribute, mapping), converted|
            next unless attributes.key?(attribute)
            converted[mapping] = attributes[attribute]
          end
        else
          raise ArgumentError
        end
      end

      # Public: Convert a Hash of Salesforce attributes to a format compatible
      # with a specific platform.
      #
      # to_format  - A String or Class reflecting the record type for which the
      #              attribute Hash is being compiled.
      # attributes - A Hash of attributes, with keys corresponding to the
      #              Salesforce attribute names.
      #
      # Examples
      #
      #   map = AttributeMap.new(
      #     MyClass,
      #     "Object__c",
      #     some_key: "SomeField__c",
      #   )
      #
      #   map.convert_from_salesforce(
      #     "Object__c",
      #     "Some_Field__c" => "some value",
      #   )
      #   # => { "Some_Field__c" => "some value" }
      #
      #   map.convert_from_salesforce(
      #     MyClass,
      #     "Some_Field__c" => "some other value",
      #   )
      #   # => { some_key: "some other value" }
      #
      # Returns a Hash.
      def convert_from_salesforce(to_format, attributes)
        case @types[to_format]
        when :database
          @fields.each_with_object({}) do |(attribute, mapping), converted|
            next unless attributes.key?(mapping)
            converted[attribute] = attributes[mapping]
          end
        when :salesforce
          attributes.dup
        else
          raise ArgumentError
        end
      end

    end

  end

end
