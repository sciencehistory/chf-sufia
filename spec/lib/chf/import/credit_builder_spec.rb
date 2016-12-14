require 'rails_helper'

describe Chf::Import::CreditBuilder do
  let(:builder) { described_class.new }
  let(:credit) do
    [
      { "id": "8p58pd01g",
      "role": "photographer",
      "name": "Will Brown",
      "label": "Photographed by Will Brown" }
    ]
  end
  let(:work) { FactoryGirl.create(:generic_work) }
  before { builder.build(work, credit) }

  it 'creates a Credit object' do
    expect(work.additional_credit.first).to be_a Credit
    expect(work.additional_credit.count).to eq 1
  end

  it 'has the right data' do
    expect(work.additional_credit.first.id).not_to eq '8p58pd01g'
    expect(work.additional_credit.first.role).to eq 'photographer'
    expect(work.additional_credit.first.name).to eq 'Will Brown'
    expect(work.additional_credit.first.display_label).to eq 'Photographed by Will Brown'
  end
end
