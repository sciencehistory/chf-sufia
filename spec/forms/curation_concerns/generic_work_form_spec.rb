# Generated via
#  `rails generate curation_concerns:work GenericWork`
require 'rails_helper'

describe CurationConcerns::GenericWorkForm do
  let(:user)   { FactoryGirl.create(:user) }
  let(:work)    { GenericWork.new }
  let(:ability) { Ability.new(user) }
  let(:form)    { described_class.new(work, ability) }

  describe "form terms" do
    it "are all above the fold" do
      expect(form.secondary_terms).to be_empty
    end
    it "exclude defaults" do
      expect(form.primary_terms.count).to eq 23
      expect(form.primary_terms).not_to include :keyword
    end
    it "include local fields" do
      expect(form.primary_terms).to include :admin_note
    end
  end

  describe ".build_permitted_params" do
    it "permits nested field attributes" do
      expect(described_class.build_permitted_params).to include(
        { :inscription_attributes => [ :id, :_destroy, :location, :text ] }
      )
      expect(described_class.build_permitted_params).to include(
        { :additional_credit_attributes => [ :id, :_destroy, :role, :name ] }
      )
    end
  end

  describe "field instantiation" do
    xit "builds nested fields" do
      # expect it to  look like:
      # [#<Inscription id: nil, location: nil, text: nil>]
      expect(form.model.inscription.to_a.count).to eq 1
      expect(form.model.date_of_work.to_a.count).to eq 1
      expect(form.model.additional_credit.to_a.count).to eq 1
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
