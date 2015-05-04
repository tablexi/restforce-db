require_relative "../../../test_helper"

describe Restforce::DB::Configuration do

  configure!

  let(:secrets) { Secrets["client"] }
  let(:secrets_file) { File.expand_path("../../../../config/secrets.yml", __FILE__) }
  let(:configuration) { Restforce::DB::Configuration.new }

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
