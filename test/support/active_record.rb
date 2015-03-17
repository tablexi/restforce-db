require "active_record"

ActiveRecord::Base.logger = Logger.new("/dev/null")
ActiveRecord::Base.establish_connection(
  adapter: "sqlite3",
  database: ":memory:",
)

ActiveRecord::Schema.define do
  create_table :custom_objects do |table|
    table.column :name,          :string
    table.column :example,       :string
    table.column :salesforce_id, :string
  end
end

class CustomObject < ActiveRecord::Base; end
