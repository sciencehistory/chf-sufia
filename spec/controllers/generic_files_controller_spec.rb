require 'rails_helper'

RSpec.describe GenericFilesController do
  routes { Sufia::Engine.routes }

  before do
    @user = FactoryGirl.create(:depositor)
    sign_in @user
    @file = GenericFile.new(title: ['Blueberries for Sal'])
    @file.apply_depositor_metadata(@user.user_key)
    @file.save!
  end

  describe "edit" do
    it "includes genre" do
      get :edit, id: @file.id
      expect(response).to be_successful
      expect(assigns['form'].genre).to eq [""]
    end
  end

  describe "update" do
    it "changes to resource_type are independent from changes to genre" do
      post :update, id: @file, generic_file: {
        resource_type: ['Image']
      }
      @file.reload
      expect(@file.resource_type).to eq ['Image']
      # why is it an empty string in the form but an empty array here??
      expect(@file.genre).to eq []

      post :update, id: @file, generic_file: {
        genre: ['Photograph']
      }
      @file.reload
      expect(@file.resource_type).to eq ['Image']
      # why is it an empty string in the form but an empty array here??
      expect(@file.genre).to eq ['Photograph']
    end
  end

end


