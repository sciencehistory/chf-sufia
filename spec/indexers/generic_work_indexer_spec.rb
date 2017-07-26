require 'rails_helper'

RSpec.describe GenericWorkIndexer do
  let (:work) do
    FactoryGirl.create(:generic_work, dates_of_work: []).tap do |w|
      w.physical_container = "b2|f3|v4|p5|g234"
      w.date_of_work_attributes = [{start: "2003", finish: "2015"}, {start:'1200', start_qualifier:'century'}]
      w.inscription_attributes = [{location: "chapter 7", text: "words"}, {location: "place", text: "stuff"}]
      w.additional_credit_attributes = [{role: "photographer", name: "Puffins"}, {role: "photographer", name: "Squirrels"}]
      w.author = ["Bruce McMillan"]
      w.photographer = ["Bruce McMillan"]
      w.publisher = ["publishing house"]
      w.engraver = ["engraving professional"]
      w.save
    end
  end

  let(:service) { described_class.new(work) }
  let(:mapper) { ActiveFedora.index_field_mapper }
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
  it 'creates a maker copy field' do
    expect(solr_document[mapper.solr_name('maker_facet', :facetable)]).not_to be nil
    expect(solr_document[mapper.solr_name('maker_facet', :facetable)]).to include 'Bruce McMillan'
    expect(solr_document[mapper.solr_name('maker_facet', :facetable)]).to include 'publishing house'
    expect(solr_document[mapper.solr_name('maker_facet', :facetable)].size).to eq 3
  end

  # These are slow, was hard to get them to work reliably and be reliably testing at all
  describe "representative fields" do
    let(:width) { 100 }
    let(:height) { 200 }
    let(:width_field) { Solrizer.solr_name("representative_width", type: :integer) }
    let(:height_field) { Solrizer.solr_name("representative_height", type: :integer) }
    let(:file_id_field) { Solrizer.solr_name("representative_original_file_id") }

    describe "standard work with representative fileset" do
      let(:work) do
        FactoryGirl.create(:work, :real_public_image) do |work|
          work.representative.original_file.width = [width]
          work.representative.original_file.height = [height]
        end
      end
      it "indexes representative fields" do
        expect(solr_document[file_id_field]).to eq(work.representative.original_file.id)
        expect(solr_document[width_field]).to eq(width)
        expect(solr_document[height_field]).to eq(height)
      end
    end

    describe "work with no representative" do
      let(:work) { FactoryGirl.create(:work) }
      before do
        # precondition, make sure we set things up right
        expect(work.representative).to eq(nil)
      end
      it "indexes without those fields without raising" do
        expect(solr_document[file_id_field]).to be nil
        expect(solr_document[width_field]).to be nil
        expect(solr_document[height_field]).to be nil
      end
    end

    # This is a mess and very slow, better way to test?
    describe "work with representative child work" do
      let(:child_work) do
        FactoryGirl.create(:work, :real_public_image) do |w|
          w.representative.original_file.width = [width]
          w.representative.original_file.height = [height]
        end
      end
      let(:work) do
        FactoryGirl.create(:work) do |w|
          w.representative_id = child_work.id
          w.representative = child_work
        end
      end
      it "indexes representative from child work" do
        expect(solr_document[file_id_field]).to eq(work.representative.representative.original_file.id)
        expect(solr_document[width_field]).to eq(width)
        expect(solr_document[height_field]).to eq(height)
      end

      describe "when child work representative is updated" do
        let(:new_width) { 1000 }
        let(:new_height) { 2000 }
        let(:new_file_set) { FactoryGirl.create(:file_set, :public) }

        before do
          # have to get original work in index, so child work can find it
          # to update it.
          work.ordered_members << work.representative
          work.save!
        end

        it "updates parent work in index" do
          child_work.ordered_members << new_file_set
          IngestFileJob.perform_now(new_file_set, (Rails.root + "spec/fixtures/sample.jpg").to_s, nil)
          child_work.representative = new_file_set

          indexed_parent = SolrDocument.find(work.id)
          expect(indexed_parent["representative_original_file_id_tesim"]).not_to include(new_file_set.original_file.id)

          child_work.save!

          indexed_parent = SolrDocument.find(work.id)
          expect(indexed_parent["representative_original_file_id_tesim"]).to include(new_file_set.original_file.id)
        end
      end
    end

    describe "with with representative child work with no representative" do
      let(:work) do
        FactoryGirl.create(:work) do |w|
          w.representative = FactoryGirl.create(:work)
        end
      end
      before do
        # precondition, make sure we set things up right
        expect(work.representative.representative).to eq(nil)
      end
      it "indexes without those fields without raising" do
        expect(solr_document[file_id_field]).to be nil
        expect(solr_document[width_field]).to be nil
        expect(solr_document[height_field]).to be nil
      end
    end

    describe "with self-pointing representative" do
      # pathological, but since the model can do it, we want to make sure
      # we don't infinite loop on it.
      let(:work) do
        FactoryGirl.create(:work) do |w|
          w.representative_id = w.id
          w.representative = w
        end
      end
      it "finishes with blank values" do
        expect(solr_document[file_id_field]).to be nil
        expect(solr_document[width_field]).to be nil
        expect(solr_document[height_field]).to be nil
      end
    end
  end
end
