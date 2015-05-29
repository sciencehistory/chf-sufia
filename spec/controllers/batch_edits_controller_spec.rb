require 'rails_helper'

RSpec.describe BatchEditsController do

  let (:files) { [] }
  let (:user) { FactoryGirl.create(:depositor) }
  before do
    sign_in user
    2.times { files << GenericFile.new.tap do |f|
        f.resource_type = ['Image']
        f.apply_depositor_metadata(user.user_key)
        f.save!
      end
    }
    controller.batch = files.map { |f| f.id }
  end


  describe "edit" do
    context "when the file had no initial genre" do
      it "should include genre, empty" do
        get :edit
        expect(response).to be_successful
        expect(assigns[:terms]).to include :genre_string
        expect(assigns[:generic_file].genre_string).to eq [""]
      end
    end

    context "when the file does have initial genre" do
      before do
        files[0].genre_string = ['Photograph']
        files[0].save!
      end
      it "should prepopulate form fields" do
        get :edit
        expect(response).to be_successful
        expect(assigns[:terms]).to include :genre_string
        expect(assigns[:generic_file].genre_string).to eq ["Photograph"]
      end
    end
  end

  describe "update" do
    let(:attributes) {
      { genre_string: ["Photograph", "Print"] }
    }

    # note: this test was passing when I didn't expect it to;
    # didn't get to the bottom of it and moving on for now since
    # batch edits are going to change drastically post-PCDM
    it "should update the records" do
      put :update, update_type: "update", generic_file: attributes
      expect(response).to be_redirect
      expect(GenericFile.find(files[0].id).genre_string).to eq ["Photograph", "Print"]
    end
  end

end

