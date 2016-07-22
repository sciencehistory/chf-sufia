require 'rails_helper'

describe 'curation_concerns/base/show.html.erb' do
  let(:solr_document) {
    SolrDocument.new(
      id: '999',
      object_profile_ssm: ["{\"id\":\"999\"}"],
      has_model_ssim: ['GenericWork'],
      human_readable_type_tesim: ['Generic Work'],
      title_tesim: ['The Thinks You Can Think'],
      #physical_container: 'b2|f3|v4|p5|g234',
      identifier_tesim: ['object-2004', 'bib-b123456789', 'object-2004-09.003']
    )
  }

  let(:ability) { nil }
  let(:presenter) do
    CurationConcerns::GenericWorkShowPresenter.new(solr_document, ability)
  end

  before do
    stub_template 'curation_concerns/base/_relationships.html.erb' => ''
    stub_template 'curation_concerns/base/_show_actions.html.erb' => ''
    stub_template 'curation_concerns/base/_representative_media.html.erb' => ''
    stub_template 'curation_concerns/base/_social_media.html.erb' => ''
    stub_template 'curation_concerns/base/_citations.html.erb' => ''
    stub_template 'curation_concerns/base/_items.html.erb' => ''
    assign(:presenter, presenter)
    render
  end

  # these aren't in the index yet?
  describe 'local fields display' do
    xit 'parses physical container' do
      expect(rendered).to match /Box 2, Folder 3, Volume 4, Part 5, Page 234/
    end
    it 'parses external ID' do
      expect(rendered).to match /Object ID: 2004/
      expect(rendered).to match /Sierra Bib. No.: b123456789/
      expect(rendered).to match /Object ID: 2004-09.003/
    end
  end

end
