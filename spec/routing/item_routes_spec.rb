require 'rails_helper'

RSpec.describe "item routes", type: :routing do
  let(:work) { FactoryGirl.create(:generic_work) }
  let(:file_set_id) { "some_item_id" }

  let(:original_url) { "/concern/generic_works/#{work.id}" }
  let(:original_viewer_url) { "/concern/generic_works/#{work.id}/viewer/#{file_set_id}"}

  let(:desired_url) { "/works/#{work.id}"}
  let(:desired_viewer_url) { "/works/#{work.id}/viewer/#{file_set_id}"}

  describe "route helper" do
    it "routes to new url" do
      expect(curation_concerns_generic_work_path(work)).to eq(desired_url)
    end

    it "routes to new viewer url" do
      expect(viewer_path(work, file_set_id)).to eq(desired_viewer_url)
    end
  end

  describe "routing" do
    it "routes new work url" do
      expect(:get => desired_url).to route_to(
        :controller => "curation_concerns/generic_works",
        :action => "show",
        :id => work.id
      )
    end

    it "routes new viewer url" do
      expect(:get => desired_viewer_url).to route_to(
        :controller => "curation_concerns/generic_works",
        :action => "show",
        :id => work.id,
        :filesetid => file_set_id
      )
    end
  end

  describe "redirects" do
    include RSpec::Rails::RequestExampleGroup

    it "original show urls" do
      get(original_url)
      expect(response).to redirect_to(desired_url)
    end

    it "original viewer urls" do
      get(original_viewer_url)
      expect(response).to redirect_to(desired_viewer_url)
    end
  end

  # I'm not sure why these even exist in sufia, they don't seem to effect breadcrumbs
  # which is what I'd predict they'd be for. But we need them to work too.
  describe "child routes" do
    let(:parent)  { FactoryGirl.create(:generic_work, ordered_members: [work]) }

    let(:original_url) { "/concern/parent/#{parent.id}/generic_works/#{work.id}" }
    let(:original_viewer_url) { "/concern/parent/#{parent.id}/generic_works/#{work.id}/viewer/#{file_set_id}"}

    let(:desired_url) { "/parent/#{parent.id}/works/#{work.id}"}
    let(:desired_viewer_url) { "/parent/#{parent.id}/works/#{work.id}/viewer/#{file_set_id}"}

    describe "polymorphic url" do
      include ActionDispatch::Routing::PolymorphicRoutes
      it "routes" do
        # this is the one sufia/CC does
        # https://github.com/samvera/curation_concerns/blob/v1.7.8/app/services/curation_concerns/contextual_path.rb#L13
        expect(polymorphic_path([:curation_concerns, :parent, :generic_work], parent_id: parent.id, id: work.id)).to eq(desired_url)
      end
    end

    describe "routing" do
      it "routes new work url" do
        expect(:get => desired_url).to route_to(
          :controller => "curation_concerns/generic_works",
          :action => "show",
          :id => work.id,
          :parent_id => parent.id
        )
      end

      it "routes new viewer url" do
        expect(:get => desired_viewer_url).to route_to(
          :controller => "curation_concerns/generic_works",
          :action => "show",
          :id => work.id,
          :parent_id => parent.id,
          :filesetid => file_set_id
        )
      end
    end

    describe "redirects" do
      include RSpec::Rails::RequestExampleGroup

      it "original show urls" do
        get(original_url)
        expect(response).to redirect_to(desired_url)
      end

      it "original viewer urls" do
        get(original_viewer_url)
        expect(response).to redirect_to(desired_viewer_url)
      end
    end
  end
end
