module Restforce

  module DB

    class Configuration

      attr_accessor *%i(
        username
        password
        security_token
        client_id
        client_secret
        host
      )

    end

  end

end
