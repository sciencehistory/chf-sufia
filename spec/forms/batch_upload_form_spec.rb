require 'rails_helper'

describe BatchUploadForm do
  let(:user)   { FactoryGirl.create(:user) }
  let(:model)    { BatchUploadItem.new }
  let(:ability) { Ability.new(user) }
  let(:form)    { described_class.new(model, ability) }

  describe "form model" do
    it "uses BatchUploadItem" do
      expect(form.model.class).to eq BatchUploadItem
    end
  end

  describe "form terms" do
    it "exclude defaults" do
      # title and resource type go on the upload form
      expect(form.primary_terms.count).to eq 26
      expect(form.primary_terms).not_to include :keyword
    end
    it "requires 2 fields" do
      # no title field on this form; it's taken from the upload form
      # only required field is identifier
      expect(form.required_fields.count).to eq 1
    end
  end

  it_behaves_like "work_form_behavior"

end
