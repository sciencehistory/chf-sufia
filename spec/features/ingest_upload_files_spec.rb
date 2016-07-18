require 'rails_helper'

RSpec.feature "Uploading files via web form", :type => :feature do
  background do
    sign_in FactoryGirl.create(:depositor)
    visit '/concern/generic_works/new'
  end

  scenario "Deposit agreement has been removed" do
    expect(page).not_to have_text "By saving this work I agree to the Deposit Agreement"
  end

end
