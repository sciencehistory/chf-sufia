require 'rails_helper'
require_dependency Rails.root.join('lib','chf','metadata','single_value_migration')

RSpec.describe 'CHF::Metadata::SingleValueMigration' do
  let(:subject) { CHF::Metadata::SingleValueMigration }
  let!(:work1) do
    FactoryGirl.create(:work).tap do |w|
      w.title = ["Single Title"]
      w.save
    end
  end
  let!(:work2) do
    FactoryGirl.create(:work).tap do |w|
      w.title = ["First Title", "Second Title"]
      w.description = ["It's a thing."]
      w.save
    end
  end
  let!(:work3) do
    FactoryGirl.create(:work).tap do |w|
      w.title = ["First Title", "Second Title", "Third Title"]
      w.description = ["It's a thing.", "It's also stuff."]
      w.save
    end
  end

  describe '.run' do
    it 'moves titles and merges descriptions' do
      subject.run
      expect(work1.reload.title.count).to eq 1
      expect(work1.additional_title.count).to eq 0
      expect(work2.reload.title.count).to eq 1
      expect(work2.additional_title.count).to eq 1
      expect(work3.reload.title.count).to eq 1
      expect(work3.additional_title.count).to eq 2
      expect(work1.description.count).to eq 0
      expect(work2.description.count).to eq 1
      expect(work2.description.first).to eq "It's a thing."
      expect(work3.description.count).to eq 1
      expect(work3.description.first).to eq "It's a thing.\r\n\r\nIt's also stuff."
    end
  end
end
