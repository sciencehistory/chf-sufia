require 'rails_helper'

RSpec.describe Credit do

  describe "rdf type" do
    subject { described_class.new.type }
    it { is_expected.to eq [ ::RDF::URI.new("http://chemheritage.org/ns/credit") ] }
  end

  describe "add attributes" do
    before do
      subject.role = 'photographer'
      subject.name = 'Leo Leoni'
    end
    it "has values" do
      expect(subject.role).to eq 'photographer'
      expect(subject.name).to eq 'Leo Leoni'
    end
    describe "saving object" do
      it "creates the label" do
        subject.save
        expect(subject.display_label).to eq 'Photographed by Leo Leoni'
      end
    end
  end

  describe 'id' do
    # kind of a sloppy test
    it 'is not a NOID' do
      subject.save
      expect(subject.id.length).to be > 9
    end
  end

end
