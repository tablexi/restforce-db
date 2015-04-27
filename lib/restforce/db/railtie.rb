module Restforce

  module DB

    # Restforce::DB::Railtie makes Restforce::DB's rake tasks available to any
    # Rails application which requires the gem.
    class Railtie < Rails::Railtie

      railtie_name :"restforce-db"

      rake_tasks do
        load "tasks/restforce.rake"
      end

    end

  end

end
