# Restforce::DB

Restforce::DB is an attempt at simplifying data integrations between a Salesforce setup and a Rails application. It provides a background worker which continuously polls for updated records both in Salesforce and in the database, and updates both systems with that data according to user-defined attribute mappings.

## Installation

Add this line to your application's Gemfile:

```ruby
gem "restforce-db"
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install restforce-db

## Usage

First, you'll want to install the default bin and configuration files, which is handled by the included Rails generator:

    $ bundle exec rails g restforce:install

This gem assumes that you're running Rails 4 or greater, therefore the `bin` file should be checked into the repository with the rest of your code. The `config/restforce-db.yml` file should be managed the same way you manage your secrets files, and probably not checked into the repository.

### Update your model schema

In order to keep your database records in sync with Salesforce, the table will need to store a reference to its associated Salesforce record. A generator is included to trivially add this `salesforce_id` column to your tables:

    $ bundle exec rails g restforce:migration MyModel
    $ bundle exec rake db:migrate

### Register a mapping

To register a Salesforce mapping in an `ActiveRecord` model, you need to add a few lines of DSL-style code to your class definition:

```ruby
class MyModel < ActiveRecord::Base

  include Restforce::DB::Model

  map_to "Object__c", name: "Name", color: "Color__c"

end
```

This will automatically register the model with an entry in the `Restforce::DB::RecordType` collection.

To run the worker, you'll want to run the binstub installed through the generator (see above). Then you can run the self-daemonizing executable.

        $ bin/restforce-db start

By default, this will load the credentials at the same location the generator installed them. You can explicitly pass the location of your configuration file with the `-c` option:

        $ bin/restforce-db -c /path/to/my/config.yml start

For additional information and a full set of options, you can run:

        $ bin/restforce-db -h

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release` to create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

1. Fork it ( https://github.com/tablexi/restforce-db/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Ensure that your changes pass all style checks and tests (`rake`)
4. Commit your changes (`git commit -am 'Add some feature'`)
5. Push to the branch (`git push origin my-new-feature`)
6. Create a new Pull Request
