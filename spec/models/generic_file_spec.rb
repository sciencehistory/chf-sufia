require 'rails_helper'

RSpec.describe GenericFile do
  # test for new fields
  it { is_expected.to respond_to(:artist) }

  it 'uses the right predicate for overriden fields' do
    {
      artist: 'http://id.loc.gov/vocabulary/relators/art',
      creator: 'http://purl.org/dc/elements/1.1/creator',
      contributor: 'http://purl.org/dc/elements/1.1/contributor',
      date_created: 'http://www.ebu.ch/metadata/ontologies/ebucore/ebucore#dateCreated',
      language: 'http://purl.org/dc/elements/1.1/language',
      publisher: 'http://purl.org/dc/elements/1.1/publisher',
      resource_type: 'http://purl.org/dc/elements/1.1/type',
      rights: 'http://purl.org/dc/elements/1.1/rights',
    }.each do |field_name, uri|
      predicate = GenericFile.reflect_on_property(field_name).predicate.to_s
      expect(predicate).to eq uri
    end
  end

  describe 'marc relator creator / contributor fields' do
    let :generic_file do
      described_class.create(title: ['title1']) do |gf|
        gf.apply_depositor_metadata('dpt')
        gf.interviewee = ['Beckett, Samuel']
      end
    end
    it 'has a single interviewee' do
      expect(generic_file.interviewee.count).to eq 1
      expect(generic_file.interviewee).to include 'Beckett, Samuel'
    end
  end


end
