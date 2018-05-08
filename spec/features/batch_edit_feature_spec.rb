require 'rails_helper'

RSpec.feature "Batch Edit form", js: true do
  let(:user) { FactoryGirl.create(:depositor) }
  let!(:w1) { FactoryGirl.create(:generic_work, :with_complete_metadata) }
  let!(:w2) { FactoryGirl.create(:generic_work, :with_complete_metadata) }
  let!(:w3) { FactoryGirl.create(:generic_work, :with_complete_metadata) }
  let!(:w4) { FactoryGirl.create(:generic_work, :with_complete_metadata) }
  let!(:w5) { FactoryGirl.create(:generic_work, :with_complete_metadata) }

  before do
    login_as(user, :scope => :user)
    Capybara.page.current_window.resize_to(1600, 1200)
  end

  scenario "Create six new works, then batch edit three of them." do
    w1, w2, w3, w4, w5 = GenericWork.all
    new_test_work('Title 1', 'xyz')
    my_work = GenericWork.where(title: ["Title 1"]).first
    aci = my_work.access_control_id

    # Just a quick hack so these works actually
    # show up on the "My Works" page. Otherwise we
    # can't batch-edit them.
    [w1, w2, w3, w4, w5].each do |w|
      w.access_control_id=aci
      w.depositor='depositor@example.com'
      w.save
    end


    visit '/dashboard/works'
    find_by_id("batch_document_#{w2.id}").click
    find_by_id("batch_document_#{w3.id}").click
    find_by_id("batch_document_#{w4.id}").click
    click_button "Edit Selected"
    click_link "Department"
    select "Center for Oral History", from: "generic_work[division]"
    click_button "Save changes"
    expect(page).to have_content 'Changes Saved'
    w1, w2, w3, w4, w5, w6 = GenericWork.all
    expect( w1.division).to eq('Library')
    expect( w2.division).to eq('Center for Oral History')
    expect( w3.division).to eq('Center for Oral History')
    expect( w4.division).to eq('Center for Oral History')
    expect( w5.division).to eq('Library')
    expect( w6.division).to eq('')
  end

  def new_test_work(title, bib_num)
      visit new_curation_concerns_generic_work_path
      fill_in("generic_work[title]", with: title)
      within(".form-group.generic_work_identifier") do
        within first(".field-wrapper") do
          select "Sierra Bib. No."
          fill_in "generic_work[bib_external_id][]", with: bib_num
        end
      end
      select "Image", from: "generic_work[resource_type][]"
      choose "Your Institution"
      click_button "Save"
      puts "Saved a work."
  end
end
