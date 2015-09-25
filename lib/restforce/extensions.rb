module Restforce

  # :nodoc:
  class Middleware::Authentication < Restforce::Middleware # rubocop:disable Style/ClassAndModuleChildren

    # Internal: Get an error message for the passed response. Overrides the
    # default behavior of the middleware to correctly handle broken responses
    # from Faraday.
    #
    # Returns a String.
    def error_message(response)
      if response.status == 0
        "Request was closed prematurely"
      else
        "#{response.body['error']}: #{response.body['error_description']}"
      end
    end

  end

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
