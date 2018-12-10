require 'rails_helper'

RSpec.describe CollectionsController,  type: :controller do

  let(:user) { FactoryGirl.create(:user) }

  before do
    sign_in user
  end

  it 'Creates a collection; scrubs HTML' do
    collection_params = {
      "collection"=>{
        "title"=>["title"],
        "description"=>["<a href=\"https://www.nytimes.com\" target=\"_blank\">The New York Times.</a>"]
      }
    }
    post :create, params: collection_params
    expect(Collection.first.description.first).to eq "<a href=\"https://www.nytimes.com\">The New York Times.</a>"
  end
end
