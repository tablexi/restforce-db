module Restforce

  class SObject

    def update(attributes)
      ensure_id
      @client.update(sobject_type, attributes.merge("Id" => self.Id))
      merge!(attributes)
    end

    def update!(attributes)
      ensure_id
      @client.update!(sobject_type, attributes.merge("Id" => self.Id))
      merge!(attributes)
    end
  end

end
