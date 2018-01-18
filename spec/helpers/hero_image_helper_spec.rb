require 'rails_helper'

describe HeroImageHelper do
  describe "#hero_link" do
    context "when the hero image isn't in the repository" do
      it "links nowhere" do
        out = helper.hero_link('notanid')
        node = Capybara::Node::Simple.new(out)
        expect(node).to have_link 'Hero Image not in this repository', href: '#'
      end
    end

    context "when the image is in the repository" do
      let(:work) { FactoryGirl.build(:work, id: '12345') }
      let(:solr_doc) { SolrDocument.new(work.to_solr) }
      before do
        allow(SolrDocument).to receive(:find).with(work.id).and_return(solr_doc)
      end
      it "gives link to the object" do
        out = helper.hero_link(work.id)
        node = Capybara::Node::Simple.new(out)
        expect(node).to have_link work.title.first, href: "/works/#{work.id}"
      end
    end
  end
end
