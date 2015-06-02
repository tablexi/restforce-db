require_relative "../../../test_helper"

describe Restforce::DB::Configuration do

  configure!

  let(:secrets) { Secrets["client"] }
  let(:secrets_file) { File.expand_path("../../../../config/secrets.yml", __FILE__) }
  let(:configuration) { Restforce::DB::Configuration.new }

  describe "#before" do

    it "does nothing if invoked without a block" do
      # NOTE: We're asserting that this invocation doesn't raise an error.
      configuration.before
    end

    it "does not invoke the hook on configuration" do
      a = 1

      configuration.before { a += 1 }

      expect(a).to_equal 1
    end

    it "invokes the configured hook when called without a block" do
      a = 1

      configuration.before { a += 1 }
      configuration.before

      expect(a).to_equal 2
    end

    it "invokes the configured hook with passed arguments" do
      a = 1

      configuration.before { |b| a += b }
      configuration.before(2)

      expect(a).to_equal 3
    end
  end

  describe "#logger" do

    it "defaults to a null logger" do
      log_device = configuration.logger.instance_variable_get("@logdev")
      expect(log_device.dev.path).to_equal "/dev/null"
    end
  end

  describe "#load" do

    describe "when all configurations are supplied" do
      before do
        configuration.load(secrets)
      end

      it "loads the credentials from a passed hash" do
        expect(configuration.username).to_equal secrets["username"]
        expect(configuration.password).to_equal secrets["password"]
        expect(configuration.security_token).to_equal secrets["security_token"]
        expect(configuration.client_id).to_equal secrets["client_id"]
        expect(configuration.client_secret).to_equal secrets["client_secret"]
        expect(configuration.host).to_equal secrets["host"]
      end
    end

    describe "when the loaded configuration is missing one or more keys" do
      let(:secrets) { {} }

      it "raises an error" do
        expect(-> { configuration.load(secrets) }).to_raise(ArgumentError)
      end
    end
  end

  describe "#parse" do
    before do
      configuration.parse(secrets_file)
    end

    it "loads the credentials from a YAML file" do
      expect(configuration.username).to_equal secrets["username"]
      expect(configuration.password).to_equal secrets["password"]
      expect(configuration.security_token).to_equal secrets["security_token"]
      expect(configuration.client_id).to_equal secrets["client_id"]
      expect(configuration.client_secret).to_equal secrets["client_secret"]
      expect(configuration.host).to_equal secrets["host"]
    end
  end

end
