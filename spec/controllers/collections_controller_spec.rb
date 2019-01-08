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
        "description"=>["""<a href=\"https://www.nytimes.com\" target=\"_blank\">The New York Times.</a>
          <i>italics</i>
          <b>bold</b>
          <cite>citation</cite>
          <goat>this tag should not make it, except for its contents</goat>
          <i>and this tag should get closed."""
        ]
      }
    }
    post :create, params: collection_params


    result = Collection.first.description.first
    expect(result).to include("<a href=\"https://www.nytimes.com\">The New York Times.</a>")
    expect(result).to include("<i>italics</i>")
    expect(result).to include("<b>bold</b>")
    expect(result).not_to include("goat")
    expect(result).to include("this tag should not make it, except for its contents")
    expect(result).to include("<cite>citation</cite>")
    expect(result).to include("<i>and this tag should get closed.</i>")

  end
end
