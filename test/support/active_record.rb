require "active_record"

ActiveRecord::Base.logger = Logger.new("/dev/null")
ActiveRecord::Base.establish_connection(
  adapter: "sqlite3",
  database: ":memory:",
)
ActiveSupport::TestCase.test_order = :random

ActiveRecord::Schema.define do

  create_table :custom_objects do |table|
    table.column :name,            :string
    table.column :example,         :string
    table.column :user_id,         :integer
    table.column :salesforce_id,   :string
    table.column :synchronized_at, :datetime
    table.timestamps null: false
  end

  add_index :custom_objects, :salesforce_id

  create_table :details do |table|
    table.column :name,             :string
    table.column :custom_object_id, :integer
    table.column :salesforce_id,    :string
    table.column :synchronized_at,  :datetime
    table.timestamps null: false
  end

  add_index :details, :salesforce_id

  create_table :users do |table|
    table.column :email,           :string
    table.column :favorite_id,     :integer
    table.column :salesforce_id,   :string
    table.column :synchronized_at, :datetime
    table.timestamps null: false
  end

  add_index :users, :salesforce_id

end

# :nodoc:
class CustomObject < ActiveRecord::Base

  belongs_to :user, inverse_of: :custom_object, autosave: true
  has_many :admirers, class_name: "User", inverse_of: :favorite, foreign_key: :favorite_id
  has_many :details, inverse_of: :custom_object

end

# :nodoc:
class Detail < ActiveRecord::Base

  belongs_to :custom_object, inverse_of: :details

end

# :nodoc:
class User < ActiveRecord::Base

  has_one :custom_object, inverse_of: :user
  belongs_to :favorite, class_name: "CustomObject", inverse_of: :admirers, foreign_key: :favorite_id

end
