require 'rails_helper'

RSpec.feature "Editing metadata of generic file", :type => :feature do
  background do
    @user = FactoryGirl.create(:depositor)
    sign_in @user
    @file = GenericFile.new
    @file.apply_depositor_metadata(@user.user_key)
    @file.physical_container = 'v8|p2'
    @file.save!
  end

  context "the single file edit form" do

    scenario "has our locally-added fields" do
      @file.identifier = ['object-2008.043.002']
      @file.save!
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
      expect(form_field).to have_content 'Image'
      expect(form_field).not_to have_content 'Article'
      # creator / contributor fields
      # identifier is required
      id_div = find('div.generic_file_identifier')
      expect(id_div.find('label', text: 'External ID')['class']).to include('required')
      expect(id_div.first('li')).to have_select('generic_file_identifier', selected: 'Object ID')
      expect(id_div.first('li')).to have_field('generic_file_object_external_id', with: '2008.043.002')
      pc_div = find('div.generic_file_physical_container')
      expect(pc_div).to have_text 'Box'
      expect(pc_div).to have_text 'Part'
      expect(pc_div.first('input#generic_file_volume').value).to eq '8'
    end

    scenario "saves a new maker field", js: true  do
      visit "/files/#{@file.id}/edit"
      expect(page).to have_text 'Maker'
      expect(page).to have_no_field('generic_file_photographer')
      select 'Artist', from: 'generic_file_maker'
      fill_in 'generic_file_artist', with: 'Zeldog'
      click_button 'Save Descriptions'
      expect(page.find('div.generic_file_maker').first('input').value).to eq('Zeldog')
    end

#    # this test passing erroneously
#    scenario "saves a new external id field", js: true  do
#      visit "/files/#{@file.id}/edit"
#      select 'Bibliographic No.', from: 'generic_file_identifier'
#      fill_in 'generic_file_bib_external_id', with: 'b123456789'
#      click_button 'Update Generic file'
#      id_div = find('div.generic_file_identifier')
#      expect(id_div.first('li')).to have_field('generic_file_bib_external_id', with: 'b123456789')
#    end

    # This test giving false negatives. basically any test which involves
    # submitting the form and then viewing the results isn't working right.
    scenario "deletes a maker field", exclude: true, js: true  do
      @file.artist = ['puffins', 'hattla']
      @file.photographer = ['ladinsky']
      @file.author = ['hafiz']
      @file.save!
      visit "/files/#{@file.id}/edit"
      expect(page).to have_field('generic_file_photographer')
      maker_div = page.find('div.generic_file_maker')
      node = maker_div.first('input#generic_file_photographer')
      #TODO: add a second deletion
      #node = maker_div.first('input#generic_file_artist')
      parent = node.find(:xpath, '..')
      # now click remove within that parent <li>
      parent.find_button('Remove').click
      page.find_button('Update Generic file').click
      expect(page).to have_field('generic_file_author')
      # this passes, but if you actually look at the file the photographer is still there.
      expect(page).to have_no_field('generic_file_photographer')
      #visit "/files/#{@file.id}"
      #desc_data = page.find('dl.file-show-descriptions')
      #expect(desc_data).to have_text 'hafiz'
      #expect(desc_data).not_to have_text 'ladinsky'
    end
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
  end

  scenario "the batch edits form has a field for genre" do
    visit "/batch_edits/edit?batch_document_ids[]=#{@file.id}"
    expect(page).to have_text('Genre')
    expect(page).not_to have_text('Genre string')
    expect(page).to have_text('Interviewee')
  end

end
