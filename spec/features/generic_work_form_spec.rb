require 'rails_helper'

RSpec.feature "Editing metadata of generic work" do
  background do
    @user = FactoryGirl.create(:depositor)
    sign_in @user
    @work = GenericWork.new
    @work.apply_depositor_metadata(@user.user_key)
    @work.title = ['Test work']
    @work.physical_container = 'v8|p2|g100'
    @work.identifier = ['object-2008.043.002']
    @work.save!
    visit "/concern/generic_works/#{@work.id}/edit"
  end

  context "the single work edit form" do

    # oringally i intended to use this test to fill in all the values and make sure
    # they persisted on the browse view page. but capybara is awful so that remains a distant dream.
    # basically any test which involves submitting the form and then viewing the results isn't working right.
    # tests relying on js behavior are also currently unattainable. (e.g. filling out some form fields)
    scenario "has our locally-added fields", js: true do
      # fields removed from work
      expect(page).not_to have_text('Keyword')
      expect(page).not_to have_text('Date created')
      # fields added to work
      # genre field
      #expect(page).not_to have_text('Genre string')
      # resource types
      form_field = find('#generic_work_resource_type')
      #expect(form_field).to have_css "option[value='http://purl.org/dc/dcmitype/StillImage']"
      expect(form_field).to have_css "option[value='Image']"
      expect(form_field).to have_no_css "option[value='http://schema.org/Article']"
      # creator / contributor fields
      # identifier fills in correctly
      id_div = find('div.generic_work_identifier')
      expect(id_div.first('li')).to have_select('generic_work_identifier', selected: 'Object ID')
      expect(id_div.first('li')).to have_field('generic_work_object_external_id', with: '2008.043.002')
      # physical container fills in correctly
      pc_div = find('div.generic_work_physical_container')
      expect(pc_div).to have_text 'Box'
      expect(pc_div).to have_text 'Part'
      expect(pc_div.first('input#generic_work_volume').value).to eq '8'
      expect(pc_div.first('input#generic_work_page').value).to eq '100'
      page.assert_selector('input.physical_container', :count => 5)
    end

    xscenario "saves a new maker field", js: true  do
      # TODO: test one or more nested fields'
      expect(page).to have_text 'Maker'
      expect(page).to have_no_field('generic_work_photographer')
      select 'Artist', from: 'generic_work_maker'
      # change below to look more like the "fills in correctly" tests.
      fill_in 'generic_work_artist', with: 'Zeldog'
      click_button 'Save Descriptions'
      expect(page.find('div.generic_work_maker').first('input').value).to eq('Zeldog')
    end

    # this test passing erroneously
    xscenario "saves a new external id field", js: true  do
      visit "/concern/generic_works/#{@work.id}/edit"
      select 'Bibliographic No.', from: 'generic_work_identifier'
      fill_in 'generic_work_bib_external_id', with: 'b123456789'
      click_button 'Update Generic work'
      id_div = find('div.generic_work_identifier')
      expect(id_div.first('li')).to have_field('generic_work_bib_external_id', with: 'b123456789')
    end

    xscenario "deletes a maker field", exclude: true, js: true  do
      @work.artist = ['puffins', 'hattla']
      @work.photographer = ['ladinsky']
      @work.author = ['hafiz']
      @work.save!
      visit "/concern/generic_works/#{@work.id}/edit"
      expect(page).to have_field('generic_work_photographer')
      maker_div = page.find('div.generic_work_maker')
      node = maker_div.first('input#generic_work_photographer')
      #TODO: add a second deletion
      #node = maker_div.first('input#generic_work_artist')
      parent = node.find(:xpath, '..')
      # now click remove within that parent <li>
      parent.find_button('Remove').click
      page.find_button('Update Generic work').click
      expect(page).to have_field('generic_work_author')
      # this passes, but if you actually look at the work the photographer is still there.
      expect(page).to have_no_field('generic_work_photographer')
      #visit "/concern/generic_works/#{@work.id}"
      #desc_data = page.find('dl.work-show-descriptions')
      #expect(desc_data).to have_text 'hafiz'
      #expect(desc_data).not_to have_text 'ladinsky'
    end
  end

  # Currently batch upload is broken?
  xscenario "the batch upload form has our locally-added fields" do
    batch = Batch.create
    @work.label = 'work.jpg'
    @work.title = ['work.jpg']
    @work.creator = [@user.user_key]

    batch.generic_works << @work
    visit "/batches/#{batch.id}/edit"
    expect(page).to have_text('Genre')
    expect(page).not_to have_text('Genre string')
    expect(find('label', text: 'Genre')['class']).not_to include('required')
  end

  # currently batch edits improvements are wishlist
  xscenario "the batch edits form has a field for genre" do
    visit "/batch_edits/edit?batch_document_ids[]=#{@work.id}"
    expect(page).to have_text('Genre')
    expect(page).not_to have_text('Genre string')
    expect(page).to have_text('Interviewee')
  end

end
