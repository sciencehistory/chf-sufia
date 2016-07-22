require 'rails_helper'

describe 'curation_concerns/base/_form.html.erb' do
  let(:work) do
    stub_model(GenericWork, id: '456')
  end
  let(:ability) { double }

  let(:form) do
    CurationConcerns::GenericWorkForm.new(work, ability)
  end

  before do
    view.lookup_context.view_paths.push 'app/views/curation_concerns'
    allow(work).to receive(:member_ids).and_return([1, 2])
    #allow(view).to receive(:curation_concern).and_return(work)
    allow(controller).to receive(:current_user).and_return(stub_model(User))
    assign(:form, form)
  end

  let(:page) do
    render
    Capybara::Node::Simple.new(rendered)
  end

  it "renders hidden fields" do
    expect(page).to have_selector "input#generic_work_artist[type='hidden']", visible: false
    # 5? are sufia-supplied (resource_type?)
    expect(page.all("input[type='hidden']", visible: false).count).to eq 19
  end

  it "renders a nested attribute field" do
    expect(page).to have_selector "#generic_work_inscription_attributes_0_location"
    expect(page).to have_selector "#generic_work_inscription_attributes_0_text"
  end

  #TODO: it's not a multiple selector; it's a dropdown with a "more" button. (FIXME)
  xit "should render a single-select rights field" do
    expect(page).to have_selector "select[name='generic_work[rights][]']"
    expect(page).not_to have_selector "select[id='generic_work_rights'][multiple='multiple']"
  end
end
