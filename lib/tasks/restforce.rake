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

  desc "Pull down the requested Salesforce data for the specified model"
  task :populate, [:model, :salesforce_model, :field] => :environment do |_, args|
    raise ArgumentError, "An ActiveRecord model name must be supplied" unless args[:model]
    raise ArgumentError, "A Salesforce model name must be supplied" unless args[:salesforce_model]
    raise ArgumentError, "An attribute name must be supplied" unless args[:field]

    Rails.application.eager_load!

    model = args[:model].constantize
    field = args[:field].to_sym

    mapping = Restforce::DB::Registry[model].detect do |m|
      m.salesforce_model == args[:salesforce_model]
    end

    raise ArgumentError, "No Mapping was found between #{args[:model]} and #{args[:salesforce_model]}" unless mapping

    model.where.not(mapping.lookup_column => nil).find_each do |record|
      salesforce_id = record.send(mapping.lookup_column)
      salesforce_instance = mapping.salesforce_record_type.find(salesforce_id)
      next unless salesforce_instance

      attributes = mapping.convert(model, salesforce_instance.attributes)
      record.update!(field => attributes[field])
      record.touch(:synchronized_at)
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

      "ABCDEFGHIJKLMNOPQRSTUVWXYZ012345"[flag]
    end

    puts sfid + suffixes.join
  end
end
