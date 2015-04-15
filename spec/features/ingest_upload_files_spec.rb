require 'spec_helper'

describe "Uploading files via web form", :type => :feature do
  before do
    sign_in
    #sign_in :user
    click_link "Upload"
  end

  it "does not have terms of service field" do
    expect(page).not_to have_text "You must agree to Sufia's Deposit Agreement before starting your upload"
    expect(page).not_to have_field "terms_of_service"
  end

  context "upload button", :js do
    it "is enabled, with no hover message" do
      attach_file("files[]", File.dirname(__FILE__)+"/../../spec/fixtures/image.png")
      expect(page).not_to have_css("button#main_upload_start[disabled]")
      find('#main_upload_start_span').hover
      expect(page).not_to have_text "Please accept Deposit Agreement before you can upload."
    end
  end

end
