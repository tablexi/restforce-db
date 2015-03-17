require "minitest/autorun"
require "yaml"

$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require "restforce/db"

secrets_file = File.expand_path("../config/secrets.yml", __FILE__)
Secrets = YAML.load_file(secrets_file)
