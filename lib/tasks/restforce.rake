namespace :restforce do
  desc "Populate all records for a specific model within the specified timespan"
  task :seed, [:model, :start_time, :end_time, :config] => :environment do |_, args|
    raise ArgumentError, "the name of an ActiveRecord model must be supplied" unless args[:model]

    config_file = args[:config] || Rails.root.join("config", "restforce-db.yml")
    Restforce::DB.configure { |config| config.parse(config_file) }

    runner = Restforce::DB::Runner.new
    runner.after = Time.parse(args[:start_time]) if args[:start_time].present?
    runner.before = Time.parse(args[:end_time]) if args[:end_time].present?

    target_class = args[:model].constantize
    Restforce::DB::Registry[target_class].each do |mapping|
      puts "SYNCHRONIZING between #{mapping.database_model.name} and #{mapping.salesforce_model}"
      Restforce::DB::Initializer.new(mapping, runner).run
      puts "DONE"
    end
  end
end
