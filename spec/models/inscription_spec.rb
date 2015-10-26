require 'rails_helper'

RSpec.describe Inscription do

  describe "rdf type" do
    subject { described_class.new.type }
    it { is_expected.to eq [ ::RDF::URI.new("http://purl.org/vra/Inscription") ] }
  end

  describe "add attributes" do
    before do
      subject.location = 'page 2'
      subject.text = 'to my best friend'
    end
    it "has values" do
      expect(subject.location).to eq 'page 2'
      expect(subject.text).to eq 'to my best friend'
    end
  end

  describe 'id' do
    # kind of a sloppy test
    it 'is a NOID' do
      subject.save
      expect(subject.id.length).to eq 9
    end
  end

end
