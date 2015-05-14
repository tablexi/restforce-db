module Restforce

  module DB

    # Restforce::DB::AttributeMap encapsulates the logic for converting between
    # various representations of attribute hashes.
    #
    # For the purposes of our mappings, a "normalized" attribute Hash maps the
    # Salesforce field names to Salesforce-compatible values. Value conversion
    # into and out of the database occurs through a lightweight Adapter object.
    class AttributeMap

      # Public: Initialize a Restforce::DB::AttributeMap.
      #
      # database_model   - A Class compatible with ActiveRecord::Base.
      # salesforce_model - A String name of an object type in Salesforce.
      # fields           - A Hash of mappings between database columns and
      #                    fields in Salesforce.
      # adapter          - An adapter object which should be used to convert
      #                    between data formats.
      def initialize(database_model, salesforce_model, fields = {}, adapter = Adapter.new)
        @database_model = database_model
        @salesforce_model = salesforce_model
        @fields = fields
        @adapter = adapter

        @types = {
          database_model   => :database,
          salesforce_model => :salesforce,
        }
      end

      # Public: Build a normalized Hash of attributes from the appropriate set
      # of mappings. The keys of the resulting mapping Hash will correspond to
      # the Salesforce field names.
      #
      # from_format - A String or Class reflecting the record type from which
      #               the attribute Hash is being compiled.
      #
      # Yields a series of attribute names.
      # Returns a Hash.
      def attributes(from_format)
        case @types[from_format]
        when :salesforce
          @fields.values.each_with_object({}) do |mapping, values|
            values[mapping] = yield(mapping)
          end
        when :database
          attributes = @fields.keys.each_with_object({}) do |attribute, values|
            values[attribute] = yield(attribute)
          end
          attributes = @adapter.from_database(attributes)

          @fields.each_with_object({}) do |(attribute, mapping), final|
            final[mapping] = attributes[attribute]
          end
        else
          raise ArgumentError
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
      #   mapping.convert(MyClass, "Some_Field__c" => "some value")
      #   # => { some_key: "some value" }
      #
      #   mapping.convert("Object__c", "Some_Field__c" => "some other value")
      #   # => { "Some_Field__c" => "some other value" }
      #
      # Returns a Hash.
      def convert(to_format, attributes)
        case @types[to_format]
        when :database
          attributes = @fields.each_with_object({}) do |(attribute, mapping), converted|
            next unless attributes.key?(mapping)
            converted[attribute] = attributes[mapping]
          end

          @adapter.to_database(attributes)
        when :salesforce
          attributes.dup
        else
          raise ArgumentError
        end
      end

    end

  end

end
