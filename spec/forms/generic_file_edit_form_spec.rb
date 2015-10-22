require 'rails_helper'

RSpec.describe GenericFileEditForm do
  subject { GenericFileEditForm.new(file) }
  let(:file) { GenericFile.new }

  describe ".build_permitted_params" do
    it "should permit nested inscription attributes" do
      expect(described_class.build_permitted_params).to include(
        {
          :inscription_attributes => [
            :id,
            :_destroy,
            :location,
            :text
          ]
        }
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
  end

end
