require "minitest-vcr"
require "vcr"
require "webmock"

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

  c.filter_sensitive_data("<api_version>") do
    api_version = Secrets["client"].fetch("api_version") do
      Restforce::DB::Configuration::DEFAULT_API_VERSION
    end

    "v#{api_version}"
  end
end

MinitestVcr::Spec.configure!
