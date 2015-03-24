require "rails/generators/active_record"

module Restforce

  # :nodoc:
  class MigrationGenerator < ActiveRecord::Generators::Base

    source_root File.expand_path("../../templates", __FILE__)

    # :nodoc:
    def create_migration_file
      migration_template "migration.rb", "db/migrate/add_#{singular_name}_salesforce_binding.rb"
    end

  end

end
