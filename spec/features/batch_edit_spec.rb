# frozen_string_literal: true
require 'rails_helper'
require 'features/support/batch_edit_actions'

# Currently when capybara clicks 'check_all' it disables the sort toolbar as expected
# but does not enable the batch operations toolbar. Therefore these tests are all broken.
# Timeboxed investigation yielded nothing; for now these feature tests are
# TODO
xdescribe "Batch management of works", type: :feature, js: true do
  let(:current_user) { FactoryGirl.create(:user) }
  let!(:work1)       { FactoryGirl.create(:public_work, :with_complete_metadata, depositor: current_user.email) }
  let!(:work2)       { FactoryGirl.create(:public_work, :with_complete_metadata, depositor: current_user.email) }

  before do
    #sign_in_with_named_js(:batch_edit, current_user, disable_animations: true)
    sign_in current_user
    visit "/dashboard/works"
  end

  context "when editing and viewing multiple works" do

    it "edits a field and displays the changes", js: true do
      check("check_all")
      click_on("batch-edit")
      batch_edit_fields.each do |field|
        fill_in_batch_edit_field(field, with: "Updated batch #{field}")
      end
      work1.reload
      work2.reload
      batch_edit_fields.each do |field|
        expect(work1.send(field)).to contain_exactly("Updated batch #{field}")
        expect(work2.send(field)).to contain_exactly("Updated batch #{field}")
      end
    end

    it "displays the field's existing value" do
      within("textarea#batch_edit_item_description") do
        expect(page).to have_content("descriptiondescription")
      end
      expect(page).to have_css "input#batch_edit_item_contributor[value*='contributorcontributor']"
      expect(page).to have_css "input#batch_edit_item_keyword[value*='tagtag']"
      expect(page).to have_css "input#batch_edit_item_based_near[value*='based_nearbased_near']"
      expect(page).to have_css "input#batch_edit_item_language[value*='languagelanguage']"
      expect(page).to have_css "input#batch_edit_item_creator[value*='creatorcreator']"
      expect(page).to have_css "input#batch_edit_item_publisher[value*='publisherpublisher']"
      expect(page).to have_css "input#batch_edit_item_subject[value*='subjectsubject']"
      expect(page).to have_css "input#batch_edit_item_related_url[value*='http://example.org/TheRelatedURLLink/']"
    end
  end

  context "when selecting multiple works for deletion", js: true do
    subject { GenericWork.count }
    before do
      check "check_all"
      click_button "Delete Selected"
    end
    it { is_expected.to be_zero }
  end
end
