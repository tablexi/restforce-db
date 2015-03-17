module Restforce

  module DB

    # Internal: Restforce::DB::Configuration exposes a handful of straightforward
    # write and read methods to allow users to configure Restforce::DB.
    class Configuration

      attr_accessor(*%i(
        username
        password
        security_token
        client_id
        client_secret
        host
      ))

    end

  end

end
