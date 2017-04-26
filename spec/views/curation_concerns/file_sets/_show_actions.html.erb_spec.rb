require 'rails_helper'

RSpec.describe 'curation_concerns/file_sets/_show_actions.html.erb', type: :view do
  let(:object_profile) { ["{\"id\":\"999\"}"] }
  let(:solr_document) do
    SolrDocument.new(
      id: '999',
      object_profile_ssm: object_profile,
      has_model_ssim: ['FileSet'],
      human_readable_type_tesim: ['File'],
    )
  end
  let(:ability) { double }
  let(:presenter) { CurationConcerns::GenericWorkShowPresenter.new(solr_document, ability) }

  before do
    stub_template 'curation_concerns/file_sets/_social_media.html.erb' => ''
    view.lookup_context.view_paths.push 'app/views/curation_concerns/base'
    allow(view).to receive(:current_ability).and_return(ability)
    allow(presenter).to receive(:editor?).and_return(true)
    assign(:presenter, presenter)
  end


  context "as an editor" do
    before do
      allow(ability).to receive(:can?).with(:destroy, solr_document).and_return(false)
      render 'curation_concerns/file_sets/show_actions.html.erb', presenter: presenter
    end
    it "hides delete links" do
      expect(rendered).not_to have_link("Delete This File")
    end
  end

  context "as an admin" do
    before do
      allow(ability).to receive(:can?).with(:destroy, solr_document).and_return(true)
      render 'curation_concerns/file_sets/show_actions.html.erb', presenter: presenter
    end
    it "shows delete links" do
      expect(rendered).to have_link("Delete This File")
    end
  end
end
