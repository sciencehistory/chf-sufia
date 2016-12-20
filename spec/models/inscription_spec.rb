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

    # kind of a sloppy test
    it 'id is not a NOID' do
      subject.save
      expect(subject.id.length).to be > 9
    end
  end

  describe '#compose_label' do
    before do
      subject.location = "Bottom center"
      subject.text = "Sir Humphrey Davy Bart.\r\nPresident of the Royal Society &c. &c. &c."
    end

    it 'replaces \r\n with space' do
      expect(subject.send(:compose_label)).to eq "(Bottom center) \"Sir Humphrey Davy Bart. President of the Royal Society &c. &c. &c.\""
    end
  end

 end
