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
  has_one :chef, inverse_of: :restaurant
  has_many :dishes, inverse_of: :restaurant

  sync_with("Restaurant__c", :always) do
    where "StarRating__c > 4"
    has_many :dishes, through: "Restaurant__c"
    belongs_to :chef, through: %w(Chef__c Cuisine__c)
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

  sync_with("Dish__c", :passive) do
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

_Coming Soon_

#### Lookup Conditions

`where` accepts one or more query strings which will be used to filter _all_ queries performed for the specific mapping. In the example above, Restaurant objects will only be detected in Salesforce if they exceed a certain value for the `StarRating__c` field.

Individual conditions supplied to `where` will be appended together with `AND` clauses, and must be composed of valid [`SOQL`](http://www.salesforce.com/us/developer/docs/soql_sosl/).

#### Field Mappings

`maps` defines a set of direct field-to-field mappings. It takes a Hash as an argument; the keys should line up with your ActiveRecord attribute names, while the values should line up with the matching field names in Salesforce.

#### Associations

Associations in `Restforce::DB` can be a little tricky, as they depend on your ActiveRecord association mappings, but are independent of those mappings, and can even (as seen above) seem to conflict with them.

If your Salesforce objects have parity with your ActiveRecord models, your association mappings will likely have parity, as well. But, as demonstrated above, you should define your association mappings based on your Salesforce schema.

##### `belongs_to`

This defines an association type in which the Lookup (i.e., foreign key) _is on the mapped Salesforce model_. In the example above, the `Restaurant__c` object type in Salesforce has two Lookup fields:

- `Chef__c`, which corresponds to the `Contact` object type, and
- `Cuisine__c`, which corresponds to the `Cuisine__c` object type
 
Thus, the `Restaurant__c` mapping declares a `belongs_to` relationship to `:chef`, with a `:through` argument referencing both of the Lookups used by the mappings on the associated `Chef` class.

As shown above, the `:through` option may contain _an array of Lookup field names_, which may be useful if more than one mapping on the associated ActiveRecord model refers to a Lookup on the same Salesforce record.

##### `has_one`

This defines an inverse relationship for a `belongs_to` relationship. In the example above, `Dish` defines _two_ `has_one` relationships with `:restaurant`, one for each mapping. The `:through` arguments for each call to `has_one` correspond to the relevant Lookup field on the parent object.

In the above example, given the relationships defined between our records, we can ascertain that `Restaurant__c.Chef__c` is a `Lookup(Contact)` field in Salesforce, while `Restaurant__c.Cuisine__c` is a `Lookup(Cuisine__c)`.

##### `has_many`

This _also_ defines an inverse relationship for a `belongs_to` relationship. The chief difference between this and `has_one` is that `has_many` relationships are one-to-many, rather than one-to-one.

In the above example, `Dish__c` is a Salesforce object type which references the `Restaurant__c` object type through an aptly-named Lookup. There is no restriction on the number of `Dish__c` objects that may reference the same `Restaurant__c`, so we define this relationship as a `has_many` associaition in our `Restaurant` mapping.

__NOTE__: Unlike `has_one` associations, `has_many` associations do not currently support multiple lookups from the same model. The Lookup is assumed
to always refer to the `Id` of the parent object.

### Run the daemon

To actually perform this system synchronization, you'll want to run the binstub installed through the generator (see above). This will daemonize a process which loops repeatedly to continuously synchronize your database and your Salesforce account, according to the established mappings.

    $ bundle exec bin/restforce-db start

By default, this will load the credentials at the same location the generator installed them. You can explicitly pass the location of your configuration file with the `-c` option:

    $ bundle exec bin/restforce-db -c /path/to/my/config.yml start

For additional information and a full set of options, you can run:

    $ bundle exec bin/restforce-db -h

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release` to create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Caveats

- **Update Prioritization.** When synchronization occurs, the most recently updated record, Salesforce or database, gets to make the final call about the values of _all_ of the fields it observes. This means that race conditions can and probably will happen if both systems are updated within the same polling interval.
- **API Usage.** This gem performs most of its functionality via the Salesforce API (by way of the [`restforce`](https://github.com/ejholmes/restforce) gem). If you're at risk of hitting your Salesforce API limits, this may not be the right approach for you.

## Contributing

1. Fork it ( https://github.com/tablexi/restforce-db/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Ensure that your changes pass all style checks and tests (`rake`)
4. Commit your changes (`git commit -am 'Add some feature'`)
5. Push to the branch (`git push origin my-new-feature`)
6. Create a new Pull Request
