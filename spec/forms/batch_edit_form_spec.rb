require 'rails_helper'

RSpec.describe BatchEditForm do
  let(:model) { GenericWork.new }
  let(:work1) { FactoryGirl.create :generic_work, title: ["title 1"], language: ['en'], contributor: ['contributor1'], description: ['description1'], rights: ['rights1'], subject: ['subject1'], identifier: ['id1'], related_url: ['related_url1'] }
  let(:work2) { FactoryGirl.create :generic_work, title: ["title 2"], publisher: ['Rand McNally'], language: ['en'], resource_type: ['bar'], contributor: ['contributor2'], description: ['description2'], rights: ['rights2'], subject: ['subject2'], identifier: ['id2'], related_url: ['related_url2'] }
  let(:batch) { [work1.id, work2.id] }
  let(:form) { described_class.new(model, ability, batch) }
  let(:ability) { Ability.new(user) }
  let(:user) { FactoryGirl.build(:user, display_name: 'Jill Z. User') }

  describe "::build_permitted_params" do
    subject { described_class }
    it 'includes visibility' do
      expect(subject.build_permitted_params).to include(:visibility)
    end
  end

  describe "#terms" do
    subject { form.terms }
    it do
      is_expected.to eq [
        :additional_title,
        :identifier,
        :admin_note,
        :resource_type,
        :subject, :language,
        :related_url,
        :artist,
        :author,
        :addressee,
        :creator_of_work,
        :contributor,
        :engraver,
        :interviewee,
        :interviewer,
        :manufacturer,
        :photographer,
        :printer_of_plates,
        :publisher,
        :place_of_interview,
        :place_of_manufacture,
        :place_of_publication,
        :place_of_creation,
        :genre_string,
        :medium,
        :extent,
        :description,
        :series_arrangement,
        :rights
      ]
    end
  end

  describe "#model" do
    it "combines the models in the batch" do
      expect(form.model.contributor).to match_array ["contributor1", "contributor2"]
      expect(form.model.description).to match_array ["description1", "description2"]
      expect(form.model.resource_type).to match_array ["bar"]
      expect(form.model.rights).to match_array ["rights1", "rights2"]
      expect(form.model.publisher).to match_array ["Rand McNally"]
      expect(form.model.subject).to match_array ["subject1", "subject2"]
      expect(form.model.language).to match_array ["en"]
      expect(form.model.identifier).to match_array ["id1", "id2"]
      expect(form.model.related_url).to match_array ["related_url1", "related_url2"]
    end
  end
end
