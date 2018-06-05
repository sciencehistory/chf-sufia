require 'rails_helper'

RSpec.describe UsersController do
  routes { Sufia::Engine.routes }

  context "a guest user" do
    before { allow(controller.current_ability).to receive(:can?).and_return(false) }
    it 'shows the unauthorized message' do
      get :index
      expect(response).to be_redirect
    end
  end

  context "a staff user" do
    before { allow(controller.current_ability).to receive(:can?).and_return(true) }
    it "routes to the list of all users" do
      get :index
      expect(response).to be_successful
    end
  end
end
