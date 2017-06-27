require 'spec_helper'

describe CurationConcerns::GenericWorkShowPresenter do
  let(:request) { double }

  let(:ability) { nil }
  let(:presenter) { described_class.new(solr_document, ability, request) }



  describe "#viewable_member_presenters" do
    let(:public_work_with_one_file) do
      work = FactoryGirl.build(:work, visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC)
      work.ordered_members << FactoryGirl.create(:file_set, visibility: file_visibility)
      work.save!
      work
    end

    let(:solr_document) { SolrDocument.new(public_work_with_one_file.to_solr) }

    describe "with admin user"  do
      let(:user) { FactoryGirl.create(:user, :admin) }
      let(:ability) { Ability.new(user) }

      describe "protected file" do
        let(:file_visibility) { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED }
        it "reveals protected file" do
          expect(presenter.viewable_member_presenters.length).to eq 1
        end
      end

      describe "public file" do
        let(:file_visibility) { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC }
        it "reveals public file" do
          expect(presenter.viewable_member_presenters.length).to eq 1
        end
      end
    end

    describe "with non-logged in user" do
      let(:ability) { Ability.new(nil) }

      describe "protected file" do
        let(:file_visibility) { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED }
        it "does not reveal protected file" do
          expect(presenter.viewable_member_presenters.length).to eq 0
        end
      end

      describe "public file" do
        let(:file_visibility) { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC }
        it "reveals public file" do
          expect(presenter.viewable_member_presenters.length).to eq 1
        end
      end
    end
  end
end
