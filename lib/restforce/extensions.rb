module Restforce

  # :nodoc:
  class SObject

    # Public: Update the Salesforce record with the passed attributes.
    #
    # attributes - A Hash of attributes to assign to the record.
    #
    # Raises on update error.
    def update!(attributes)
      ensure_id
      @client.update!(sobject_type, attributes.merge("Id" => self.Id))
      merge!(attributes)
    end

  end

end
