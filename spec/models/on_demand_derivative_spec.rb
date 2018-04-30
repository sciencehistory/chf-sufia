require 'rails_helper'

RSpec.describe OnDemandDerivative do
  let(:work) { FactoryGirl.create(:work) }
  let(:instance) { OnDemandDerivative.create(work_id: work.id, deriv_type: "pdf", checksum: "fake_checksum")}
  let(:sample_file_path) { (Rails.root + "spec/fixtures/sample.jpg").to_s }

  describe "with S3" do
    before do
      # stub our ENV to say to use S3 bucket
      original_lookup = CHF::Env.method(:lookup)
      allow(CHF::Env).to receive(:lookup) do |key|
        if key.to_s == "derivatives_cache_bucket"
          "test_fake_bucket"
        else
          original_lookup.call(key)
        end
      end

      # tell S3 to stub
      allow(instance.send(:resource_locator)).to receive(:s3_bucket).and_return(Aws::S3::Resource.new(stub_responses: true).bucket("test_fake_bucket"))
    end

    it "writes to store" do
      # just a smoke test, since we have S3 all stubbed out
      instance.write_from_path(sample_file_path)
    end

    it "has a url" do
      expect(instance.url).to start_with("https://")
    end
  end
end
