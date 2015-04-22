require 'spec_helper'

feature "Uploading files via web form", :type => :feature do
  background do
    sign_in FactoryGirl.create(:depositor)
    click_link "Upload"
  end

  scenario "form does not have terms of service field" do
    expect(page).not_to have_text "You must agree to Sufia's Deposit Agreement before starting your upload"
    expect(page).not_to have_field "terms_of_service"
  end

  scenario "upload button is enabled, with no hover message", :js do
    attach_file("files[]", "#{Rails.root.to_s}/spec/fixtures/image.png")
    expect(page).not_to have_css("button#main_upload_start[disabled]")
    find('#main_upload_start_span').hover
    expect(page).not_to have_text "Please accept Deposit Agreement before you can upload."
  end

end
