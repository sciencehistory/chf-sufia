require 'rails_helper'

RSpec.describe GenericFileEditForm do
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

end
