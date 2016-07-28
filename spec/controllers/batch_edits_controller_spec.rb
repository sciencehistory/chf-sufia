require 'rails_helper'

describe BatchEditsController do
  let(:user) { FactoryGirl.create(:user) }
  before do
    sign_in user
    allow_any_instance_of(User).to receive(:groups).and_return([])
    request.env["HTTP_REFERER"] = 'test.host/original_page'
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
end
