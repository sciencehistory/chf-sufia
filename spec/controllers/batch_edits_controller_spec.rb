require 'rails_helper'

describe BatchEditsController do
  let(:user) { FactoryGirl.create(:user) }
  before do
    sign_in user
    allow_any_instance_of(User).to receive(:groups).and_return([])
    request.env["HTTP_REFERER"] = 'test.host/original_page'
    #allow_any_instance_of(Devise::Strategies::HttpHeaderAuthenticatable).to receive(:remote_user).and_return(user.login)
  end

  describe "#edit" do
    let(:one) { FactoryGirl.create(:work, creator: ["Fred"], title: ["abc"], language: ['en']) }
    let(:two) { FactoryGirl.create(:work, creator: ["Wilma"], title: ["abc2"], publisher: ['Rand McNally'], language: ['en'], resource_type: ['bar']) }
    before do
      controller.batch = [one.id, two.id]
      expect(controller).to receive(:can?).with(:edit, one.id).and_return(true)
      expect(controller).to receive(:can?).with(:edit, two.id).and_return(true)
    end

    it "is successful" do
      allow(controller.request).to receive(:referer).and_return('foo')
      expect(controller).to receive(:add_breadcrumb).with(I18n.t('sufia.dashboard.title'), Sufia::Engine.routes.url_helpers.dashboard_index_path)
      expect(controller).to receive(:add_breadcrumb).with(I18n.t('sufia.dashboard.my.works'), Sufia::Engine.routes.url_helpers.dashboard_works_path)
      get :edit
      expect(response).to be_successful
      expect(assigns[:form].terms).not_to include :keyword
      expect(assigns[:form].class).to eq BatchEditForm
    end
  end

  describe "#form_class" do
    subject { described_class.new }
    it 'uses batch edit form' do
      expect(subject.send(:form_class)).to eq ::BatchEditForm
    end
  end

  describe "#update" do
    let(:work1) { FactoryGirl.create(:private_work, depositor: user.email) }
    let(:work2) { FactoryGirl.create(:private_work, depositor: user.email) }
    let(:work3) { FactoryGirl.create(:public_work,  depositor: user.email) }

    before { request.env["HTTP_REFERER"] = "where_i_came_from" }

    context "when changing visibility" do
      let(:parameters) do
        {
          update_type:        "update",
          batch_edit_item:    { visibility: "authenticated" },
          batch_document_ids: [work1.id, work2.id]
        }
      end

      it "applies the new visibility to all works" do
        expect(VisibilityCopyJob).to receive(:perform_later).twice
        expect(InheritPermissionsJob).not_to receive(:perform_later)
        put :update, parameters.as_json
        expect(work1.reload.visibility).to eq("authenticated")
        expect(work2.reload.visibility).to eq("authenticated")
      end
    end

    context "when changing external identifier" do
      let(:parameters) do
        {
          update_type:        "update",
          batch_edit_item:    {
            identifier: ["bib_external_id", "", ""],
            bib_external_id: ["12345"]
          },
          batch_document_ids: [work1.id, work2.id]
        }
      end

      it "applies the new identifier to all works" do
        put :update, parameters.as_json
        expect(work1.reload.identifier).to eq(["bib-12345"])
        expect(work2.reload.identifier).to eq(["bib-12345"])
      end
    end

    context "when visibility is nil" do
      let(:parameters) do
        {
          update_type:        "update",
          batch_edit_item:    {},
          batch_document_ids: [work1.id, work3.id]
        }
      end

      it "preserves the objects' original permissions" do
        expect(VisibilityCopyJob).not_to receive(:perform_later)
        expect(InheritPermissionsJob).not_to receive(:perform_later)
        put :update, parameters.as_json
        expect(work1.reload.visibility).to eq("restricted")
        expect(work3.reload.visibility).to eq("open")
      end
    end

    context "when visibility is unchanged" do
      let(:parameters) do
        {
          update_type:        "update",
          batch_edit_item:    { visibility: "restricted" },
          batch_document_ids: [work1.id, work2.id]
        }
      end

      it "preserves the objects' original permissions" do
        expect(VisibilityCopyJob).not_to receive(:perform_later)
        expect(InheritPermissionsJob).not_to receive(:perform_later)
        put :update, parameters.as_json
        expect(work1.reload.visibility).to eq("restricted")
        expect(work2.reload.visibility).to eq("restricted")
      end
    end

    context "when permissions are changed" do
      let(:group_permission) { { "0" => { type: "group", name: "newgroop", access: "edit" } } }
      let(:parameters) do
        {
          update_type:        "update",
          batch_edit_item:    { permissions_attributes: group_permission },
          batch_document_ids: [work1.id, work2.id]
        }
      end

      it "updates the permissions on all the works" do
        expect(VisibilityCopyJob).not_to receive(:perform_later)
        expect(InheritPermissionsJob).to receive(:perform_later).twice
        put :update, parameters.as_json
        expect(work1.reload.edit_groups).to contain_exactly("newgroop")
        expect(work2.reload.edit_groups).to contain_exactly("newgroop")
      end
    end
  end
end
