require 'rails_helper'

# BUG REPORT:
# *If* you start with an item with the "rights" property set to an empty array,
# *and* you attempt to set its "rights" to "In Copyright"
# via the batch edit screen,
# its "rights" property is unaffected. Instead, it shold be set to
# [ "http://rightsstatements.org/vocab/InC/1.0/" ].
# This appears to be pre-existing bug in Sufia.


RSpec.feature "BatchEditForm", js: true do
  let(:user) { FactoryGirl.create(:depositor) }

  scenario "bug with batch editing empty property array",
    :skip => "someday we may want to fix this bug"  do
    login_as(user, :scope => :user)
    Capybara.default_max_wait_time=60
    visit new_curation_concerns_generic_work_path
    fill_in("generic_work[title]", with: 'Title of work to edit')
    within(".form-group.generic_work_identifier") do
      within first(".field-wrapper") do
        select "Sierra Bib. No."
        fill_in "generic_work[bib_external_id][]", with: 'abcde'
      end
    end
    select "Image", from: "generic_work[resource_type][]"
    choose "Your Institution"
    click_button "Save"
    work = GenericWork.first
    work_id = work.id
    visit '/dashboard/works'
    expect(work.rights).to eq([])
    find_by_id("batch_document_#{work_id}").click
    click_button "Edit Selected"
    expect(page).to have_content 'Batch Edit Descriptions'
    click_link 'Rights'
    select 'In Copyright', :from => 'Rights'
    click_button "Save changes"
    expect(page).to have_content 'Changes Saved'
    new_value = GenericWork.find(work_id).rights
    expect(new_value).to eq(['http://rightsstatements.org/vocab/InC/1.0/'])
  end
end