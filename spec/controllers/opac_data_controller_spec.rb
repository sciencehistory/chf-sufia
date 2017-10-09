require 'rails_helper'

RSpec.describe OpacDataController do
  describe 'load data' do

    before do
      # Not specifying exact headers in stub, so it'll work in travis with different/bad/default
      # api keys too. Seems to be okay and still test what we want.

      # stub the API calls as an indirect test of clean_bibnum; potentially wasteful but tests more of the call stack.
      json_headers = { "Content-Type" => "application/json;charset=UTF-8" }
      # token body
      body = "{\"access_token\":\"A_TOKEN\",\"token_type\":\"bearer\",\"expires_in\":3600}"
      # token request: credentials in url
      stub_request(:post, "https://sandbox.iii.com/iii/sierra-api/v2/token").
        to_return(:status => 200, :body => body, :headers => json_headers)
      # bib body
      body = "{\"id\":\"1069105\",\"updatedDate\":\"2015-01-13T13:34:40Z\",\"createdDate\":\"2014-02-11T16:48:17Z\",\"deleted\":false,\"suppressed\":false,\"lang\":{\"code\":\"n/a\"},\"title\":\"Norda Essential Oil and Chemical Company Photograph Collection,\",\"author\":\"Norda Essential Oil and Chemical Company, creator\",\"materialType\":{\"code\":\"k\",\"value\":\"Photos\"},\"bibLevel\":{\"code\":\"c\",\"value\":\"COLLECTION\"},\"catalogDate\":\"2014-02-11\",\"country\":{\"code\":\"xx \",\"name\":\"Unknown or undetermined\"}}"
      # bib request: send token in header
      stub_request(:get, "https://sandbox.iii.com/iii/sierra-api/v2/bibs/1069105").
        to_return(:status => 200, :body => body, :headers => json_headers)
    end

    it 'sends json data when passed a valid bib num' do
      get :load_bib, params: {
        rec_num: 'B10691054',
        format: 'json'
      }
      expect(response).to be_successful
      parsed = JSON.parse(response.body)
      expect(parsed['id']).to eq '1069105'
      expect(parsed['bibLevel']['value']).to eq 'COLLECTION'
    end

    it 'generates a 404 for invalid or missing bib number' do
      get :load_bib, params: {
        rec_num: '54',
        format: 'json'
      }
      expect(response.status).to eq(404)
    end

  end

end
