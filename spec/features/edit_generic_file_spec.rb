require 'rails_helper'

RSpec.feature "Editing metadata of generic file", :type => :feature do
  background do
    @user = FactoryGirl.create(:depositor)
    sign_in @user
    @file = GenericFile.new
    @file.apply_depositor_metadata(@user.user_key)
    @file.save!
  end

  scenario "the single file edit form has our locally-added fields" do
    visit "/files/#{@file.id}/edit"
    # fields removed from work
    expect(page).not_to have_text('Keyword')
    expect(page).not_to have_text('Date created')
    # genre field
    expect(page).not_to have_text('Genre string')
    genre_div = find('div.generic_file_genre_string')
    expect(genre_div.find('label', text: 'Genre')['class']).not_to include('required')
    # resource types
    form_field = find('#generic_file_resource_type')
    expect(form_field).to have_content 'Still Image'
    expect(form_field).not_to have_content 'Article'
    # creator / contributor fields
    interviewee_div = find('div.generic_file_interviewee')
    # identifier is required
    id_div = find('div.generic_file_identifier')
    expect(id_div.find('label', text: 'External ID')['class']).to include('required')
  end

  scenario "the batch upload form has our locally-added fields" do
    batch = Batch.create
    @file.label = 'file.jpg'
    @file.title = ['file.jpg']
    @file.creator = [@user.user_key]

    batch.generic_files << @file
    visit "/batches/#{batch.id}/edit"
    expect(page).to have_text('Genre')
    expect(page).not_to have_text('Genre string')
    expect(find('label', text: 'Genre')['class']).not_to include('required')
    expect(page).to have_text('Interviewee')
  end

  scenario "dashboard has no link to batch edits" do
    visit "/dashboard/files"
    find("#check_all").click
    expect(find('.batch-info')).to have_button('Delete Selected')
    expect(find('.batch-info')).not_to have_button('Edit Selected')
  end

  #disable; we're not supporting batch edits yet and they're not working right
  scenario "the batch edits form has a field for genre", exclude: true do
    visit "/batch_edits/edit?batch_document_ids[]=#{@file.id}"
    expect(page).to have_text('Genre')
    expect(page).not_to have_text('Genre string')
    expect(page).to have_text('Interviewee')
  end

#  # this test should pass with out-of-the-box sufia behavior
#  scenario "successfully batch edit the keyword (tag) field", js: true do
#    visit "/batch_edits/edit?batch_document_ids[]=#{@file.id}"
#    click_link 'Keyword'
#    fill_in 'generic_file_tag', with: 'llama'
#    click_button 'Save changes'
#    expect(page).to have_css('.loading')
#    sleep 300
#    save_and_open_screenshot
#    expect(page.find('.status')).to have_text('saved') # fails here
#    visit "/files/#{@file.id}"
#    expect(page).to have_text 'llama'
#  end

end
