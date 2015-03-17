require "cgi"
require "minitest/autorun"
require "minitest/spec/expect"
require "minitest-vcr"
require "yaml"
require "webmock"
require "vcr"

$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require "restforce/db"

Dir[File.join(File.dirname(__FILE__), "support/**/*.rb")].each {|f| require f}

secrets_file = File.expand_path("../config/secrets.yml", __FILE__)
Secrets = YAML.load_file(secrets_file)

VCR.configure do |c|
  c.cassette_library_dir = "test/cassettes"
  c.hook_into :webmock

  %w(
    username
    password
    security_token
    client_id
    client_secret
    host
  ).each do |secret|
    c.filter_sensitive_data("<#{secret}>") do
      CGI.escape(Secrets["client"][secret])
    end
  end
end

MinitestVcr::Spec.configure!
