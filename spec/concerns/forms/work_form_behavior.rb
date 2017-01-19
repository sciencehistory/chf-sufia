require 'rails_helper'

shared_examples_for "work_form_behavior" do

  describe "form terms" do
    it "are all above the fold" do
      expect(form.secondary_terms).to be_empty
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
    it "builds nested fields" do
      # expect it to  look like:
      # [#<Inscription id: nil, location: nil, text: nil>]
      expect(form.model.inscription.to_a.count).to eq 1
      expect(form.model.date_of_work.to_a.count).to eq 1
      expect(form.model.additional_credit.to_a.count).to eq 1
    end
  end

  describe '.model_attributes' do
    let(:params) { ActionController::Parameters.new(
      "identifier"=>["object_external_id"], "object_external_id"=>["test"], 
      "rights"=>"http://rightsstatements.org/vocab/InC/1.0/",
      "box"=>"b", "folder"=>"f", "volume"=>"v", "part"=>"p", "page"=>"pa",
    )}
    subject { described_class.model_attributes(params) }

    context "when data is passed in specially-handled fields" do
      it 'converts rights to an array' do
        expect(subject['rights']).to eq ['http://rightsstatements.org/vocab/InC/1.0/']
      end
      it 'encodes identifier and physical container fields' do
        expect(subject['identifier']).to eq ['object-test']
        expect(subject['physical_container']).to eq 'bb|ff|vv|pp|gpa'
      end
    end

    context "when no data is submitted in specially-handled fields" do
      let(:params) { ActionController::Parameters.new(
        "thumbnail_id" => "d217qp48j"
      )}

      it 'keeps them nil' do
        expect(subject['rights']).to be_nil
        expect(subject['identifier']).to be_nil
        expect(subject['physical_container']).to be_nil
      end

    end
  end
end

