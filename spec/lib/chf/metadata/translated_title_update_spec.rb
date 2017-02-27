require 'rails_helper'
require_dependency Rails.root.join('lib','chf','metadata','translated_title_update')

RSpec.describe 'CHF::Metadata::TranslatedTitleUpdate' do
  let!(:work1) do
    FactoryGirl.create(:work).tap do |w|
      w.title = ["Comenoche [The Night Eater]"]
      w.save
    end
  end
  let!(:work2) do
    FactoryGirl.create(:work).tap do |w|
      w.title = ["A House is a House for Me"]
      w.save
    end
  end
  let(:subject) { CHF::Metadata::TranslatedTitleUpdate.new }
  before { subject.run }

  describe '#run' do
    it "doesn't catch a title with no brackets" do
      expect(subject.matches.count).to eq 1
    end
  end

  describe '#title' do
    it 'gives the non-bracketed portion' do
      expect(subject.matches[work1.id][:title]).to eq 'Comenoche'
    end
  end

  describe '#additional' do
    it 'gives the bracketed portion' do
      expect(subject.matches[work1.id][:additional]).to eq 'The Night Eater'
    end
  end


end
