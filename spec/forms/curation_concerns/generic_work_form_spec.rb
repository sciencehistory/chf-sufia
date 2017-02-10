# Generated via
#  `rails generate curation_concerns:work GenericWork`
require 'rails_helper'

describe CurationConcerns::GenericWorkForm do
  let(:user)   { FactoryGirl.create(:user) }
  let(:work)    { GenericWork.new }
  let(:ability) { Ability.new(user) }
  let(:form)    { described_class.new(work, ability) }

  describe "form terms" do
    it "exclude defaults" do
      expect(form.primary_terms.count).to eq 24
      expect(form.primary_terms).not_to include :keyword
    end
    it "requires 2 fields" do
      expect(form.required_fields.count).to eq 2
    end
  end

  it_behaves_like "work_form_behavior"

end
