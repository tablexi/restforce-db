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
end

MinitestVcr::Spec.configure!
