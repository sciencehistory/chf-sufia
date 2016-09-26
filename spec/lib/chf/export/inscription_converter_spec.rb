require 'rails_helper'

RSpec.describe Chf::Export::InscriptionConverter do
  let(:file) { FactoryGirl.create :generic_file, :with_inscription }
  let(:inscription) { file.inscription.first }
  let(:json) { "{\"id\":\"#{inscription.id}\",\"location\":\"inscriptionlocation\",\"text\":\"inscriptiontext\"}" }

  subject { described_class.new(inscription).to_json }

  describe "to_json" do
    it { is_expected.to eq json }
  end
end
