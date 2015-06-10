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
      response = @client.api_patch("sobjects/#{sobject_type}/#{self.Id}", attributes)
      update_time = response.env.response_headers["date"]

      merge!(attributes)
      merge!("SystemModstamp" => update_time)
    end

  end

end
