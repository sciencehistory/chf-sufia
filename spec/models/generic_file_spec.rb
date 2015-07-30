require 'rails_helper'

RSpec.describe GenericFile do
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
    artist: 'http://id.loc.gov/vocabulary/relators/art',
    author: 'http://id.loc.gov/vocabulary/relators/aut',
    interviewee: 'http://id.loc.gov/vocabulary/relators/ive',
    interviewer: 'http://id.loc.gov/vocabulary/relators/ivr',
    manufacturer: 'http://id.loc.gov/vocabulary/relators/mfr',
    photographer: 'http://id.loc.gov/vocabulary/relators/pht',
    date_original: 'http://purl.org/dc/terms/date',
    date_published: 'http://purl.org/dc/terms/issued',
    extent: 'http://purl.org/dc/terms/extent',
    medium: 'http://purl.org/dc/terms/medium',
    physical_container: 'http://bibframe.org/vocab/materialOrganization',
    place_of_interview: 'http://id.loc.gov/vocabulary/relators/evp',
    place_of_manufacture: 'http://id.loc.gov/vocabulary/relators/mfp',
    place_of_publication: 'http://id.loc.gov/vocabulary/relators/pup',
    provenance: 'http://purl.org/dc/terms/provenance',
    rights_holder: 'http://chemheritage.org/ns/rightsHolder',
    series_arrangement: 'http://bibframe.org/vocab/materialHierarchicalLevel',
  }

  it 'uses a different predicate for each field' do
    f = GenericFile.new
    predicates = f.resource.fields.map do |attr|
      GenericFile.reflect_on_property(attr).predicate.to_s
    end
    dup = predicates.select{ |element| predicates.count(element) > 1 }
    expect(dup).to be_empty
  end

  it 'uses the right predicate for new and overriden fields' do
    MyFields.each do |field_name, uri|
      predicate = GenericFile.reflect_on_property(field_name).predicate.to_s
      expect(predicate).to eq uri
    end
  end

  describe 'Correctly populates one new and one overriden field' do
    let :generic_file do
      described_class.create(title: ['title1']) do |gf|
        gf.apply_depositor_metadata('dpt')
        gf.creator = ['Beckett, Samuel']
        gf.extent = ["infinitely long"]
      end
    end
    it 'has a single creator' do
      expect(generic_file.creator.count).to eq 1
      expect(generic_file.creator).to include 'Beckett, Samuel'
    end
    it 'has a toc' do
      expect(generic_file.extent).to eq ["infinitely long"]
    end
  end


end
