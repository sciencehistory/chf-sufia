require 'rails_helper'

## This spec won't run as part of the test suite automatically (since it doesn't end in _spec)
#   but it can be run manually to ensure that fits is set up correctly.
#   Sadly, this test worked for a minute but now is consistently failing; I
#     assume due to timeout problems when form submission loads the new page.
RSpec.feature "File characterization and derivatives generation", type: :feature, js: true do
  background do
    @user = FactoryGirl.create(:depositor)
    sign_in @user
    visit "/files/new"
  end

  scenario "uploading a file characterizes, creates derivatves" do
    attach_file("files[]", File.dirname(__FILE__)+"/../../spec/fixtures/image.png")
    click_button 'Start upload'

    expect(page).to have_content 'Apply Metadata'
    click_button 'Save'

    expect(page).to have_content 'Your files are being processed' # fails here
    click_link 'Display all details of image.png'
    expect(page).to have_content 'Original checksum'
    expect(page).not_to have_content 'not yet characterized'
    expect(page).not_to have_css('img[alt="No preview available"]')
    expect(page).to have_css 'img[alt="Download the full-sized image of image.png"]'
    find('.img-responsive').click
    expect(page.status_code).not_to eq(404)
  end
end
