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

  desc "Get the 18-character version of a 15-character Salesforce ID"
  task :convertid, [:salesforce_id] do |_, args|
    sfid = args[:salesforce_id]

    raise ArgumentError, "Provide a Salesforce ID (restforce:convertid[<salesforce_id>])" if sfid.nil?
    raise ArgumentError, "The passed Salesforce ID must be 15 characters" unless sfid.length == 15

    suffixes = sfid.scan(/.{5}/).map do |chunk|
      flag = 0
      chunk.split("").each_with_index do |char, idx|
        flag += (1 << idx) if char.upcase == char && char >= "A" && char <= "Z"
      end

      if flag <= 25
        "ABCDEFGHIJKLMNOPQRSTUVWXYZ"[flag]
      else
        "012345"[flag - 25]
      end
    end

    puts sfid + suffixes.join
  end
end
