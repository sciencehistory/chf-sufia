require 'rails_helper'

RSpec.describe Chf::Export::CreditConverter do
  let(:file) { FactoryGirl.create :generic_file, :with_additional_credit }
  let(:credit) { file.additional_credit.first }
  let(:json) { "{\"id\":\"#{credit.id}\",\"role\":\"photographer\",\"name\":\"Puffins\",\"label\":\"Photographed by Puffins\"}" }

  subject { described_class.new(credit).to_json }

  describe "to_json" do
    it { is_expected.to eq json }
  end
end
