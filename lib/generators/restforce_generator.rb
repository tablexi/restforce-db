require "rails/generators/base"

# :nodoc:
class RestforceGenerator < Rails::Generators::Base

  source_paths << File.join(File.dirname(__FILE__), "templates")

  # :nodoc:
  def create_executable_file
    template "script", "bin/restforce-db"
    chmod "bin/restforce-db", 0755
  end

end
