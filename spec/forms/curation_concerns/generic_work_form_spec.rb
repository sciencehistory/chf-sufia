# Generated via
#  `rails generate curation_concerns:work GenericWork`
require 'rails_helper'

describe CurationConcerns::GenericWorkForm do
  subject { GenericFileEditForm.new(file) }
  let(:file) { GenericFile.new }

  describe ".build_permitted_params" do
    it "should permit nested field attributes" do
      expect(described_class.build_permitted_params).to include(
        { :inscription_attributes => [ :id, :_destroy, :location, :text ] }
      )
      expect(described_class.build_permitted_params).to include(
        { :additional_credit_attributes => [ :id, :_destroy, :role, :name ] }
      )
    end
  end

  describe "field instantiation" do
    it "should build a nested inscription" do
      subject

      expect(subject.model.inscription.to_a.count).to eq 1
    end
    it "should build a nested date_of_work" do
      subject

      expect(subject.model.date_of_work.to_a.count).to eq 1
    end
    it "should build a nested additional_credit" do
      subject

      expect(subject.model.additional_credit.to_a.count).to eq 1
    end
  end

  # These tests came from the old presenter spec.
#  describe "#inscription_attributes=" do
#    it "should delegate down to the object" do
#      allow(file).to receive(:inscription_attributes=)
#
#      subject.inscription_attributes = {}
#
#      expect(file).to have_received(:inscription_attributes=).with({})
#    end
#    it "should respond to it" do
#      expect(subject).to respond_to :inscription_attributes=
#    end
#  end

end
