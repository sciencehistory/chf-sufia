require 'rails_helper'

RSpec.describe GenericFile do
  MyAssociations = {
    inscription: 'http://purl.org/vra/hasInscription',
    date_of_work: ::RDF::Vocab::DC11.date.to_s,
  }
  MyFields = {
    # overriden fields
    contributor: 'http://purl.org/dc/elements/1.1/contributor',
    language: 'http://purl.org/dc/elements/1.1/language',
    publisher: 'http://purl.org/dc/elements/1.1/publisher',
    resource_type: 'http://purl.org/dc/elements/1.1/type',
    rights: 'http://purl.org/dc/elements/1.1/rights',
    subject: 'http://purl.org/dc/elements/1.1/subject',
    # new fields
    creator_of_work: 'http://purl.org/dc/elements/1.1/creator',
    admin_notes: 'http://chemheritage.org/ns/adminNotes',
    division: 'http://chemheritage.org/ns/division',
    artist: 'http://id.loc.gov/vocabulary/relators/art',
    author: 'http://id.loc.gov/vocabulary/relators/aut',
    credit_line: 'http://bibframe.org/vocab/creditsNote',
    file_creator: 'http://www.ebu.ch/metadata/ontologies/ebucore/ebucore#hasCreator',
    interviewee: 'http://id.loc.gov/vocabulary/relators/ive',
    interviewer: 'http://id.loc.gov/vocabulary/relators/ivr',
    manufacturer: 'http://id.loc.gov/vocabulary/relators/mfr',
    photographer: 'http://id.loc.gov/vocabulary/relators/pht',
    extent: 'http://chemheritage.org/ns/extent',
    medium: 'http://chemheritage.org/ns/medium',
    physical_container: 'http://bibframe.org/vocab/materialOrganization',
    place_of_interview: 'http://id.loc.gov/vocabulary/relators/evp',
    place_of_manufacture: 'http://id.loc.gov/vocabulary/relators/mfp',
    place_of_publication: 'http://id.loc.gov/vocabulary/relators/pup',
    provenance: 'http://purl.org/dc/terms/provenance',
    rights_holder: 'http://chemheritage.org/ns/rightsHolder',
    series_arrangement: 'http://bibframe.org/vocab/materialHierarchicalLevel',
  }

  # TODO: associations may have predicates as well.
  #   how to account for those without keeping a separate list?
  it 'uses a different predicate for each field' do
    f = GenericFile.new
    predicates = f.resource.fields.map do |attr|
      GenericFile.reflect_on_property(attr).predicate.to_s
    end
    predicates << MyAssociations.values
    dup = predicates.select{ |element| predicates.count(element) > 1 }
    expect(dup).to be_empty
  end

  it 'uses the right predicate for new and overriden fields' do
    MyFields.merge(MyAssociations).each do |field_name, uri|
      predicate =
        begin
          GenericFile.reflect_on_property(field_name).predicate.to_s
        rescue NoMethodError # associations may have predicates as well
          GenericFile.reflect_on_association(field_name).predicate.to_s
        end
      expect(predicate).to eq uri
    end
  end

  describe 'Correctly populates fields' do
    let :gf do
      GenericFile.create(title: ['title1']) do |f|
        f.apply_depositor_metadata('dpt')
        f.creator = ['Beckett, Samuel']
        f.extent = ["infinitely long"]
      end
    end

    it 'has a single creator' do
      expect(gf.creator.count).to eq 1
      expect(gf.creator).to include 'Beckett, Samuel'
    end

    it 'has a toc' do
      expect(gf.extent).to eq ["infinitely long"]
    end

    describe "add a Date Range" do
      before do
        gf.date_of_work_attributes = [{start: "2003", finish: "2015"}]
      end
      it "uses TimeSpan class" do
        expect(gf.date_of_work.first).to be_kind_of TimeSpan
      end
    end

    describe "retrieve a Date Range" do
      it "finds the nested attributes" do
        gf.date_of_work_attributes = [ { start: "2003" }, { start: "2996" } ]
        gf.save!
        expect(GenericFile.find(gf.id).date_of_work.count).to eq 2 #returns both
        expect(GenericFile.load_instance_from_solr(gf.id).date_of_work.count).to eq 2 #returns both
      end
    end

    describe "with Nested Inscriptions" do

      it "uses Inscription class" do
        gf.inscription_attributes = [{location: "inside", text: "for you"}]
        expect(gf.inscription.first).to be_kind_of Inscription
      end

      it "finds the nested attributes" do
        gf.inscription_attributes = [{location: "chapter 7", text: "words"}, {location: 'place', text: 'stuff'}]
        gf.save!
        expect(GenericFile.find(gf.id).inscription.count).to eq 2 #returns both
        expect(GenericFile.load_instance_from_solr(gf.id).inscription.count).to eq 2 #returns both
      end
    end

  end
end
