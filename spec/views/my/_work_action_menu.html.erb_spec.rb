require 'rails_helper'

RSpec.describe 'my/_work_action_menu.html.erb', type: :view do
  let(:user) { FactoryGirl.create :user }
  let(:solr_document) { SolrDocument.new(attributes) }
  let(:attributes) { work.to_solr }
  let(:ability) { double }
  let(:work) { FactoryGirl.create(:work, title: ["Parent"]) }

  before do
    allow(view).to receive(:current_ability).and_return(ability)
    allow(ability).to receive(:can?).with(:create, FeaturedWork).and_return(false)
  end

  context "as an editor" do
    before do
      allow(ability).to receive(:can?).with(:destroy, solr_document).and_return(false)
      render 'my/work_action_menu.html.erb', document: solr_document, current_user: user
    end
    it "hides delete links" do
      expect(rendered).not_to have_selector("ul[aria-labelledby=\"dropdownMenu_#{work.id}\"]", text: 'Delete Work')
    end
  end

  context "as an admin" do
    before do
      allow(ability).to receive(:can?).with(:destroy, solr_document).and_return(true)
      render 'my/work_action_menu.html.erb', document: solr_document, current_user: user
    end
    it "shows delete links" do
      expect(rendered).to have_selector("ul[aria-labelledby=\"dropdownMenu_#{work.id}\"]", text: 'Delete Work')
    end
  end
end
