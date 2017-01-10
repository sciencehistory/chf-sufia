# frozen_string_literal: true
require 'rails_helper'

RSpec.describe BatchEditItem do
  let(:work1) { FactoryGirl.create(:private_work) }
  let(:work2) { FactoryGirl.create(:private_work) }

  subject { described_class.new(batch: [work1.id, work2.id]) }

  describe "#batch" do
    it 'contains expected works' do
      expect(subject.batch).to contain_exactly(work1, work2)
    end
  end

  describe "#visibility" do
    context "when all items in the batch have the same visibility" do
      it 'is given as the value' do
        expect(subject.visibility).to eq("restricted")
      end
    end

    context "when items in the batch have different visibilities" do
      let(:work2) { FactoryGirl.create(:public_work) }
      it 'is not given as the value' do
        expect(subject.visibility).to be_nil
      end
    end
  end
end
