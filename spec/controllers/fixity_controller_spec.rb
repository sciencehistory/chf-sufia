require 'rails_helper'

RSpec.describe Admin::FixityController, type: :controller do
  routes { Sufia::Engine.routes }
  context "with an authenticated user" do
    let(:user) { FactoryGirl.create(:depositor) }

    before do
      sign_in user
    end
    context 'No fixity problems' do
      it 'shows correct data' do
        byebug

        #get :index
        #expect(response).to be_success
        # Weird:
        # Prefix Verb     URI Pattern                             Controller#Action
        # admin_fixity_index GET      /admin/fixity(.:format)     admin/fixity#index

        # ActionController::UrlGenerationError
        # Exception: No route matches {:action=>"index", :controller=>"admin/fixity"}
      end
    end
  end
end