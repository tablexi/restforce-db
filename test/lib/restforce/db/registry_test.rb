describe Restforce::DB::Registry do

  configure!
  mappings!

  describe ".<<" do
    before do
      Restforce::DB::Registry << mapping
    end

    it "appends a mapping in the registry under its ActiveRecord class" do
      expect(Restforce::DB::Registry[database_model]).to_equal [mapping]
    end

    it "appends a mapping in the registry under its Salesforce object type" do
      expect(Restforce::DB::Registry[salesforce_model]).to_equal [mapping]
    end
  end

  describe ".each" do
    before do
      Restforce::DB::Registry << mapping
    end

    # Restforce::DB::Registry actually implements Enumerable, so we're just
    # going with a trivially testable portion of the Enumerable API.
    it "yields the registered record types" do
      expect(Restforce::DB::Registry.first).to_equal mapping
    end
  end

  describe ".clean!" do
    before do
      Restforce::DB::Registry << mapping
    end

    it "clears out the currently registered mappings" do
      expect(Restforce::DB::Registry.first).to_not_be_nil
      Restforce::DB::Registry.clean!
      expect(Restforce::DB::Registry.first).to_be_nil
    end
  end
end
