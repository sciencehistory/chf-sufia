require 'spec_helper'

describe CHF::RisSerializer do
  let(:work) { FactoryGirl.build(:public_work, :with_complete_metadata) }
  let(:serializer) { CHF::RisSerializer.new(work) }
  let(:serialized) { serializer.serialize }

  it "serializes" do
    expect(serialized).to be_present
  end
end
