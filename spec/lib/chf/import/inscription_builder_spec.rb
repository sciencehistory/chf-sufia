require 'rails_helper'

describe Chf::Import::InscriptionBuilder do
  let(:builder) { described_class.new }
  let(:inscription) do
    [
      { "id": "b5644r666",
        "location": "inside",
        "text": "awesomeness" }
    ]
  end
  let(:work) { FactoryGirl.create(:generic_work) }
  before { builder.build(work, inscription) }

  it 'creates a Inscription object' do
    expect(work.inscription.first).to be_a Inscription
  end

  it 'has the right data' do
    expect(work.inscription.first.id).not_to eq 'b5644r666'
    expect(work.inscription.first.location).to eq 'inside'
    expect(work.inscription.first.text).to eq 'awesomeness'
  end
end
