require 'rails_helper'

RSpec.describe GenericWorkIndexer do
  let (:work) do
    FactoryGirl.create(:generic_work).tap do |w|
      w.physical_container = "b2|f3|v4|p5|g234"
      w.date_of_work_attributes = [{start: "2003", finish: "2015"}, {start:'1200', start_qualifier:'century'}]
      w.inscription_attributes = [{location: "chapter 7", text: "words"}, {location: "place", text: "stuff"}]
      w.additional_credit_attributes = [{role: "photographer", name: "Puffins"}, {role: "photographer", name: "Squirrels"}]
      w.save
    end
  end

  let(:service) { described_class.new(work) }
  subject(:solr_document) { service.generate_solr_document }

  it 'indexes all additional credits' do
    expect(solr_document["additional_credit_tesim"].count).to eq 2
    expect(solr_document["additional_credit_tesim"]).to include 'Photographed by Puffins'
    expect(solr_document["additional_credit_tesim"]).to include 'Photographed by Squirrels'
  end
  it 'indexes all inscriptions' do
    expect(solr_document["inscription_tesim"].count).to eq 2
    expect(solr_document["inscription_tesim"]).to include '(chapter 7) "words"'
    expect(solr_document["inscription_tesim"]).to include '(place) "stuff"'
  end
  it 'indexes all dates' do
    expect(solr_document["date_of_work_tesim"].count).to eq 2
    expect(solr_document["date_of_work_tesim"]).to include '2003 - 2015'
    expect(solr_document["date_of_work_tesim"]).to include '1200s (century)'
  end

end
