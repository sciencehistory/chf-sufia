require 'rails_helper'

RSpec.describe 'curation_concerns/base/_show_actions.html.erb', type: :view do
  let(:presenter) { CurationConcerns::GenericWorkShowPresenter.new(solr_document, ability) }
  let(:solr_document) { SolrDocument.new(attributes) }
  let(:attributes) { work.to_solr }
  let(:ability) { double }
  let(:work) { FactoryGirl.create(:work, title: ["Parent"]) }

  before do
    allow(view).to receive(:current_ability).and_return(ability)
    allow(ability).to receive(:can?).with(:create, FeaturedWork).and_return(false)
    allow(presenter).to receive(:editor?).and_return(true)
    allow(presenter).to receive(:member_presenters).and_return([])
  end

  context "as an editor" do
    before do
      allow(ability).to receive(:can?).with(:destroy, solr_document).and_return(false)
      render 'curation_concerns/base/show_actions.html.erb', presenter: presenter
    end
    it "hides delete links" do
      expect(rendered).not_to have_link 'Delete'
    end
  end

  context "as an admin" do
    before do
      allow(ability).to receive(:can?).with(:destroy, solr_document).and_return(true)
      render 'curation_concerns/base/show_actions.html.erb', presenter: presenter
    end
    it "shows delete links" do
      expect(rendered).to have_link 'Delete'
    end
  end
end
