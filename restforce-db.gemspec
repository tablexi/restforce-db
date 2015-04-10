# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "restforce/db/version"

Gem::Specification.new do |spec|
  spec.name          = "restforce-db"
  spec.version       = Restforce::DB::VERSION
  spec.authors       = ["Andrew Horner"]
  spec.email         = ["andrew@tablexi.com"]

  spec.summary       = "Bind your database to Salesforce data"
  spec.description   = "
    This gem provides two-way bindings between Salesforce records and records
    in an ActiveRecord-compatible database. It leans on the Restforce library
    for Salesforce API interactions, and provides a self-daemonizing binary
    which keeps records in sync by way of a tight polling loop."

  spec.homepage      = "https://www.github.com/tablexi/restforce-db"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($RS)
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(/^exe\//) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "activerecord"
  spec.add_dependency "daemons"
  spec.add_dependency "restforce"

  spec.add_development_dependency "bundler", "~> 1.8"
  spec.add_development_dependency "database_cleaner"
  spec.add_development_dependency "minitest"
  spec.add_development_dependency "minitest-spec-expect"
  spec.add_development_dependency "minitest-vcr"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rubocop"
  spec.add_development_dependency "sqlite3"
  spec.add_development_dependency "webmock"
end
