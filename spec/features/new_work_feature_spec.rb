require 'rails_helper'

# Feature tests are really slow always, and even slower cause it's so slow
# for us to create records in samvera. So we pack a bunch of stuff
# into each scenario, even though that's often said to be not great test design.

RSpec.feature "Work form", js: true do
  let(:user) { FactoryGirl.create(:depositor) }
  before do
    login_as(user, :scope => :user)
  end


  [ :title, :additional_title, :language, :bib_num,
      :artist_name, :publisher_name,
      :inscription_location_0, :inscription_text_0,
      :inscription_location_1, :inscription_text_1,
      :inscription_location_2, :inscription_text_2 ].each do |attr|
        let(attr) { "Edited #{attr}"}
    end
  let(:date) { "2010"}

  gwia = 'generic_work_inscription_attributes'

  scenario "save, edit, and re-save new work" do

    inscription_fields = [
      inscription_location_0, inscription_location_1, inscription_location_2,
      inscription_text_0,     inscription_text_1,     inscription_text_2,
    ]

    visit new_curation_concerns_generic_work_path

    # fields removed from work
    expect(page).not_to have_text('Keyword')
    expect(page).not_to have_text('Date created')

    fill_in("generic_work[title]", with: title)
    fill_in("generic_work[additional_title][]", with: additional_title)
    fill_in("generic_work[language][]", with: additional_title)

    within(".form-group.generic_work_identifier") do
      within first(".field-wrapper") do
        select "Sierra Bib. No."
        fill_in "generic_work[bib_external_id][]", with: bib_num
      end
    end

    within(".form-group.generic_work_maker") do
      within first(".field-wrapper") do
        select "Artist"
        fill_in "generic_work[artist][]", with: artist_name
      end
      click_on "Add another Creator"
      within (".field-wrapper:nth-child(2)") do
        select "Publisher"
        fill_in "generic_work[publisher][]", with: publisher_name
      end
    end

    within(".form-group.generic_work_date_of_work") do
      fill_in "generic_work[date_of_work_attributes][0][start]", with: date
      select "circa", from: "generic_work[date_of_work_attributes][0][start_qualifier]"
    end

    within(".form-group.generic_work_inscription") do
      click_on "Add another Inscription"
      click_on "Add another Inscription"
      find_by_id("#{gwia}_0_location").set(inscription_location_0)
      find_by_id("#{gwia}_1_location").set(inscription_location_1)
      find_by_id("#{gwia}_2_location").set(inscription_location_2)
      find_by_id("#{gwia}_0_text")    .set(inscription_text_0)
      find_by_id("#{gwia}_1_text")    .set(inscription_text_1)
      find_by_id("#{gwia}_2_text")    .set(inscription_text_2)
    end

    select "Image", from: "generic_work[resource_type][]"

    choose "Your Institution"

    # Save, go to browse page, confirm everything is there
    expect {
      click_button "Save"
      newly_added_work = GenericWork.last
      expect(page).to have_current_path(curation_concerns_generic_work_path(newly_added_work.id), only_path: true)
    }.to change(GenericWork, :count).by(1)

    expect(page).to have_css("h1", text: title)
    expect(page).to have_css(".attribute.resource_type", text: "Image")
    expect(page).to have_text("Sierra Bib. No.: #{bib_num}")
    expect(page).to have_text(artist_name)
    expect(page).to have_text(publisher_name)
    expect(page).to have_text("circa #{date}")

    # Regression test for bug
    # https://github.com/sciencehistory/chf-sufia/issues/1049
    expect(page.all(:xpath, '//span[@itemprop="date_created"]').count).to eq 1

    expect(page).to have_css(".show-permission-badge", text: I18n.t("sufia.institution_name").upcase)
    inscription_fields.each {|item| expect(page).to have_text(item)}

    # This is a regression test for bug
    # https://github.com/sciencehistory/chf-sufia/issues/428 .
    # Make sure the edited inscriptions are indexed in SOLR
    # and thus displayed on the item page.
    # See also app/models/generic_work.rb and app/models/inscription.rb

    click_link 'Edit'

    # modify the inscriptions by adding *** to the end.
    inscription_fields.each {|item| item << '***' }
    find_by_id("#{gwia}_0_location").set(inscription_location_0)
    find_by_id("#{gwia}_1_location").set(inscription_location_1)
    find_by_id("#{gwia}_2_location").set(inscription_location_2)
    find_by_id("#{gwia}_0_text")    .set(inscription_text_0)
    find_by_id("#{gwia}_1_text")    .set(inscription_text_1)
    find_by_id("#{gwia}_2_text")    .set(inscription_text_2)

    click_button "Save"

    # Do we see the "***" we just added to the three
    # inscriptions and their locations, or not?
    expected_regex = 'Edited inscription_location_\d\*\*\*.*Edited inscription_text_\d\*\*\*'
    all('table.generic_work.chf-attributes tr td ul li').each do |x|
      the_contents = x['innerHTML']
      if the_contents.include? 'inscription'
        our_changes_are_visible = if the_contents.match(expected_regex).nil? then false else true end
        expect(our_changes_are_visible).to be true
      end
    end
  end
end
