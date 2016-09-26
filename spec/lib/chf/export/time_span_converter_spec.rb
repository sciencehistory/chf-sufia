require 'rails_helper'

RSpec.describe Chf::Export::TimeSpanConverter do
  let(:file) { FactoryGirl.create :generic_file, :with_date_of_work }
  let(:date_of_work) { file.date_of_work.first }
  let(:json) { "{\"id\":\"#{date_of_work.id}\",\"start\":\"1920\",\"finish\":\"1929\",\"start_qualifier\":\"circa\",\"finish_qualifier\":\"before\",\"note\":\"The twenties\"}" }

  subject { described_class.new(date_of_work).to_json }

  describe "to_json" do
    it { is_expected.to eq json }
  end
end
