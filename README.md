# Restforce::DB

Restforce::DB is an attempt at simplifying data integrations between a Salesforce setup and a Rails application. It provides a background worker which continuously polls for updated records both in Salesforce and in the database, and updates both systems with that data according to user-defined attribute mappings.

## Installation

Add this line to your application's Gemfile:

```ruby
gem "restforce-db"
```

And then execute:

    $ bundle

## Usage

First, you'll want to install the default bin and configuration files, which is handled by the included Rails generator:

    $ bundle exec rails g restforce:install

This gem assumes that you're running Rails 4 or greater, therefore the `bin` file should be checked into the repository with the rest of your code. The `config/restforce-db.yml` file should be managed the same way you manage your secrets files, and probably not checked into the repository.

### Modify your configurations

The following key-value pairs _must_ be set in your configuration file:

- `username`:
  Your Salesforce username. Note that sandbox users typically have the name of the sandbox appended to their email address, e.g. "ahorner@tablexi.com.mysandbox".

- `password`:
  Your Salesforce password.

- `security_token`:
  Your Salesforce Security Token. If you didn't receive one in your email during setup, you can find this by signing in, and visiting Setup > Personal Information > Reset your security token.

- `client_id`, `client_secret`:
  When signed in to Salesforce with the proper authorization level, navigate to Setup > App Setup > Create > Apps, and hit "New" for "Connected Apps" if no appropriate connected app has already been added. Enable OAuth settings for the app, and once it is created you should see the Consumer Key (Client ID) and Secret under the API settings for the app. If a connected app has already been created, you can simply grab the existing ID and Secret by clicking through.

- `host`:
  This hostname of the Salesforce instance. You can typically use a more generic environment URL, e.g., "login.salesforce.com".

The following _can_ be set in your configuration file:

- `api_version`:
  Restforce::DB defaults to version 29.0 of the Salesforce API. If you need a more (or less, for whatever reason) recent version of the API for your use case, you can specify an `api_version` key in your restforce-db.yml configuration. Version 29.0 or above is required for full gem functionality.

- `timeout`:
  The maximum amount of time a request to Salesforce can take before it will be interrupted. This defaults to 5 seconds.

- `adapter`:
  The HTTP adapter which should be used to make requests to Salesforce. By default, we use Net::HTTP (which is available by default in Ruby, and used by default through Faraday), but something like `typhoeus` may give better, more consistent performance for your use case. If you modify the configured adapter, be sure the relevant gem is available for your application.

### Update your model schema

In order to keep your database records in sync with Salesforce, the table will need to store a reference to its associated Salesforce record. A generator is included to trivially add a generic `salesforce_id` column to your tables:

    $ bundle exec rails g restforce:migration MyModel
    $ bundle exec rake db:migrate

If you need to activate multiple Salesforce mappings within a single model, you can do this with scoped column names. For example, if your Salesforce object types are named "Animal__c" and "Cat__c", `Restforce::DB` will look for columns named `animal_salesforce_id` and `cat_salesforce_id`.

### Register a mapping

To register a Salesforce mapping in an `ActiveRecord` model, you'll need to add a few lines of DSL-style code to the relevant class definitions:

```ruby
class Restaurant < ActiveRecord::Base

  include Restforce::DB::Model
  has_one :chef, inverse_of: :restaurant, autosave: true
  has_many :dishes, inverse_of: :restaurant

  module StyleAdapter

    def self.to_database(attributes)
      attributes.each_with_object({}) do |(key, value), final|
        final[key] = value.chomp(" in Salesforce")
      end
    end

    def self.from_database(attributes)
      attributes.each_with_object({}) do |(key, value), final|
        final[key] = "#{value} in Salesforce"
      end
    end

  end

  sync_with("Restaurant__c", :always) do
    where "StarRating__c > 4"
    has_many :dishes, through: "Restaurant__c"
    belongs_to :chef, through: %w(Chef__c Cuisine__c)

    converts_with StyleAdapter

    maps(
      name:  "Name",
      style: "Style__c",
    )
  end

end

class Chef < ActiveRecord::Base

  include Restforce::DB::Model
  belongs_to :restaurant, inverse_of: :chef

  sync_with("Contact", :passive) do
    has_one :restaurant, through: "Chef__c"
    maps name: "Name"
  end

  sync_with("Cuisine__c", :passive) do
    has_one :restaurant, through: "Cuisine__c"
    maps style: "Name"
  end

end

class Dish < ActiveRecord::Base
  
  include Restforce::DB::Model
  belongs_to :restaurant, inverse_of: :dishes

  sync_with("Dish__c", :associated, with: :restaurant) do
    belongs_to :restaurant, through: "Restaurant__c"
    maps name: "Name"
  end
  
end
```

This will automatically register the models with entries in the `Restforce::DB::Mapping` collection. This collection defines the manner in which the database and Salesforce systems will be synchronized.

Demonstrated above, `Restforce::DB` has its own DSL for defining mappings, heavily inspired by the ActiveRecord model DSL. The various options are outlined here.

#### Synchronization Strategies

The second argument to `sync_with` is a Symbol, reflecting the desired synchronization strategy for the mapping. Valid options are as follows:

##### `:always`

An `always` synchronization strategy will create any new records it encounters while polling for changes, and once the object has been persisted in both systems, will update that object any time changes are made to the matching object in the other system.

Associations defined on an `always` mapping will trigger the creation of those associated records on initial record creation.

##### `:passive`

A `passive` synchronization strategy will update all modified records that already exist in both systems, but will not directly create any new records. Objects defined with a `passive` mapping can only be created as a by-product of another mapping's association definitions (via an `always` strategy).

##### `:associated`

An `associated` synchronization strategy will create any new records it encounters _if and only if the named association for that record has already been synchronized_. The association is specified via the `:with` option. In the above example, new `Dish`/`Dish__c` records will be synchronized when the record identified by `Restaurant__c` has already been synchronized.

This allows for the selective addition of "relevant" records to the system over time.

#### Lookup Conditions

`where` accepts one or more query strings which will be used to filter _all_ queries performed for the specific mapping. In the example above, Restaurant objects will only be detected in Salesforce if they exceed a certain value for the `StarRating__c` field.

Individual conditions supplied to `where` will be appended together with `AND` clauses, and must be composed of valid [`SOQL`](http://www.salesforce.com/us/developer/docs/soql_sosl/).

#### Field Mappings

`maps` defines a set of direct field-to-field mappings. It takes a Hash as an argument; the keys should line up with your ActiveRecord attribute names, while the values should line up with the matching field names in Salesforce.

Your ActiveRecord class _must_ expose readers for each attribute in the mapping, and generally _should_ expose matching writers, though you can use an adapter object (see "Field Conversions" below) to obviate the need for the latter.

#### Field Conversions

`converts_with` defines a mapping conversion adapter. The only requirement for an adapter is that it respond to the methods `#to_database` and `#from_database`. 

- `#to_database` will be handed a "normalized" Hash, with the standard Symbol mapped attributes as keys, and the values as they are stored in Salesforce. It should return a modified version of the Hash which can be passed to `assign_attributes` for a record.

- `#from_database` will be handed a Hash with the standard Symbol mapped attributes as keys, and the values for those attributes as they are returned by the ActiveRecord object. It should return a modified version of the Hash with values suitable for storage in Salesforce.

By default, `Restforce::DB::Adapter` will be used, which simply converts times into String ISO-8601 timestamps before passing them off to Salesforce.

#### Associations

Associations in `Restforce::DB` can be a little tricky, as they depend on your ActiveRecord association mappings, but are independent of those mappings, and can even (as seen above) seem to conflict with them.

If your Salesforce objects have parity with your ActiveRecord models, your association mappings will likely have parity, as well. But, as demonstrated above, you should define your association mappings based on your Salesforce schema.

Associations can be nested arbitrarily, so it's not an issue to have several layers of `passive` record associations -- they'll all be created on initial sync.

##### `belongs_to`

This defines an association type in which the Lookup (i.e., foreign key) _is on the mapped Salesforce model_. In the example above, the `Restaurant__c` object type in Salesforce has two Lookup fields:

- `Chef__c`, which corresponds to the `Contact` object type, and
- `Cuisine__c`, which corresponds to the `Cuisine__c` object type
 
Thus, the `Restaurant__c` mapping declares a `belongs_to` relationship to `:chef`, with a `:through` argument referencing both of the Lookups used by the mappings on the associated `Chef` class.

As shown above, the `:through` option may contain _an array of Lookup field names_, which may be useful if more than one mapping on the associated ActiveRecord model refers to a Lookup on the same Salesforce record.

##### `has_one`

This defines an inverse relationship for a `belongs_to` relationship. In the example above, `Chef` defines _two_ `has_one` relationships with `:restaurant`, one for each mapping. The `:through` arguments for each call to `has_one` correspond to the relevant Lookup field on the parent object.

In the above example, given the relationships defined between our records, we can ascertain that `Restaurant__c.Chef__c` is a `Lookup(Contact)` field in Salesforce, while `Restaurant__c.Cuisine__c` is a `Lookup(Cuisine__c)`.

##### `has_many`

This _also_ defines an inverse relationship for a `belongs_to` relationship. The chief difference between this and `has_one` is that `has_many` relationships are one-to-many, rather than one-to-one.

In the above example, `Dish__c` is a Salesforce object type which references the `Restaurant__c` object type through an aptly-named Lookup. There is no restriction on the number of `Dish__c` objects that may reference the same `Restaurant__c`, so we define this relationship as a `has_many` associaition in our `Restaurant` mapping.

##### Association Caveats

- **Lookups.**
  If one side of an association has multiple possible lookup fields, the other side of the association is expected to declare a _single_ lookup field, which will be treated as the canonical lookup for that relationship. The Lookup is assumed to always refer to the `Id` of the object declaring the `has_many`/`has_one` side of the association.
  
- **Record Construction.**
  By default, _all_ associated records will be recursively constructed when a single record is synchronized into the system. This can result in a lot of unwanted/time-consuming record creation, particularly if your Salesforce account has a lot of irrelevant legacy data. You can turn off this behavior for specific associations by passing `build: false` when declaring the association in the DSL.

- **Record Persistence.** 
  See the `autosave: true` option declared for the `has_one` relationship on `Restaurant`? `Restforce::DB` requires your ActiveRecord models to handle persistence propagation.

  When inserting new records, `save!` will only be invoked on the _entry point_ record (typically a mapping with an `:always` synchronization strategy), so the persistence of any associated records must be chained through this "root" object.

  You may want to consult [the ActiveRecord documentation](http://apidock.com/rails/ActiveRecord/Associations/ClassMethods) for your specific use case.

### Add an external ID to your Salesforce objects

If your application creates any objects that you want/need to propagate to Salesforce, you'll need to expose an external ID field named `SynchronizationId__c` on the Salesforce object.

The `restforce-db` executable has a handy mechanism for automating this:

    $ ruby bin/restforce-db meta Restaurant__c Dish__c
    # => ADDING SynchronizationId__c to Restaurant__c... DONE
    # => ADDING SynchronizationId__c to Dish__c... DONE

NOTE: This script uses `bundler/inline` to get access to the `metaforce` gem at runtime. Due to some issues with Bundler's handling of inline gemfiles, the use of `ruby` versus `bundle exec` is intentional here.

### Seed your data

To populate your database with existing information from Salesforce (or vice-versa), you _could_ manually update each of the records you care about, and expect the Restforce::DB daemon to automatically pick them up when it runs. However, for any record type you need/want to _fully_ synchronize, this can be a very tedious process. 

In these cases, you can run the `seed` rake task to synchronize the initial records between both systems.

    $ bundle exec rake restforce:seed[<model>,<start_time>,<end_time>,<config>]

The task takes several arguments, most of which are optional:

- `model`: The name of the ActiveRecord model you wish to sync. This can be any model you've defined a mapping for in your application.
- `start_time` (optional): The earliest point in time for which records should be gathered.
- `end_time` (optional): The latest point in time for which records should be gathered.
- `config` (optional): The path to the file containing your Restforce::DB credentials. If not explicitly provided, the default installation file path (see above) will be used.

### Run the daemon

To actually perform this system synchronization, you'll want to run the binstub installed through the generator (see above). This will daemonize a process which loops repeatedly to continuously synchronize your database and your Salesforce account, according to the established mappings.

    $ bundle exec bin/restforce-db start

By default, this will load the credentials at the same location the generator installed them. You can explicitly pass the location of your configuration file with the `-c` option:

    $ bundle exec bin/restforce-db -c /path/to/my/config.yml start

For additional information and a full set of options, you can run:

    $ bundle exec bin/restforce-db -h

#### Configuring the daemon's runtime environment

Restforce::DB allows you to configure a block of code which will execute before the daemon process's polling loop initiates. In an initializer (or any other piece of code which will run as your application spins up), you can use `config.before` to set up this hook:

```ruby
Restforce::DB.configure do |config|
  config.before { |_worker| ActiveRecord::Base.logger = nil }
end
```

The example above would disable the default ActiveRecord logging specifically for activity triggered by the Restforce::DB daemon.

### Force-synchronizing records in your application code

If you desire to force-synchronize records from within your code (for example, if you need to ensure that changes to certain records are acknowledged synchronously), `Restforce::DB::Model` exposes a `#force_sync!` method to do so.

```ruby
restaurant = Restaurant.create!(
  name: "Chez Baloo-ey",
  style: "Molecular Gastronomy",
)
restaurant.force_sync!
```

You'll need to ensure that Restforce::DB is properly configured for your application (an initializer is recommended).

#### Testing

If you're testing your integration, and using something like VCR to record your specs, you may run into some spec order dependency issues due to Restforce::DB's global request caching. To prevent these dependencies in your spec suite, you can clear all cached data by invoking `Restforce::DB.reset` somewhere in your spec setup or teardown.

## System Caveats

- **API Usage.** 
  This gem performs most of its functionality via the Salesforce API (by way of the [`restforce`](https://github.com/ejholmes/restforce) gem). If you're at risk of hitting your Salesforce API limits, this may not be the right approach for you.

- **Update Prioritization.**
  When synchronization occurs, the most recently updated record, Salesforce or database, gets to make the final call about the values of _all_ of the fields it observes. This means that race conditions can and probably will happen if both systems are updated within the same polling interval.

  Restforce::DB attempts to mitigate this effect by tracking change timestamps for internal updates.

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
