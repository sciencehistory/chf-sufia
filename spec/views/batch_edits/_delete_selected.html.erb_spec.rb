require 'rails_helper'

RSpec.describe 'batch_edits/_delete_selected.html.erb', type: :view do
  let(:user) { FactoryGirl.create :user }
  let(:ability) { double }

  before do
    allow(view).to receive(:current_ability).and_return(ability)
  end

  context "as an editor" do
    before do
      allow(ability).to receive(:can?).with(:destroy, SolrDocument).and_return(false)
      render 'batch_edits/delete_selected', current_user: user
    end
    it "hides delete links" do
      expect(rendered).not_to have_selector('input[type="submit"][value="Delete Selected"]')
    end
  end

  context "as an admin" do
    before do
      allow(ability).to receive(:can?).with(:destroy, SolrDocument).and_return(true)
      render 'batch_edits/delete_selected', current_user: user
    end
    it "shows delete links" do
      expect(rendered).to have_selector('input[type="submit"][value="Delete Selected"]')
    end
  end
end
