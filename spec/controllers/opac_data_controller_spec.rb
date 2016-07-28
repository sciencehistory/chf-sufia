require 'rails_helper'

RSpec.describe OpacDataController do
  describe 'load data' do

    before do
      # stub the API calls as an indirect test of clean_bibnum; potentially wasteful but tests more of the call stack.
      json_headers = { "Content-Type" => "application/json;charset=UTF-8" }
      # token body
      body = "{\"access_token\":\"A_TOKEN\",\"token_type\":\"bearer\",\"expires_in\":3600}"
      # token request: credentials in url
      stub_request(:post, "https://sandbox.iii.com/iii/sierra-api/v2/token").
        with(:body => {"grant_type"=>"client_credentials"},
          :headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
              'Authorization'=>'Basic TVlfS0VZOk1ZX1NFQ1JFVA==',
              'Content-Type'=>'application/x-www-form-urlencoded', 'User-Agent'=>'Faraday v0.9.2'}).
        to_return(:status => 200, :body => body, :headers => json_headers)
      # bib body
      body = "{\"id\":\"1069105\",\"updatedDate\":\"2015-01-13T13:34:40Z\",\"createdDate\":\"2014-02-11T16:48:17Z\",\"deleted\":false,\"suppressed\":false,\"lang\":{\"code\":\"n/a\"},\"title\":\"Norda Essential Oil and Chemical Company Photograph Collection,\",\"author\":\"Norda Essential Oil and Chemical Company, creator\",\"materialType\":{\"code\":\"k\",\"value\":\"Photos\"},\"bibLevel\":{\"code\":\"c\",\"value\":\"COLLECTION\"},\"catalogDate\":\"2014-02-11\",\"country\":{\"code\":\"xx \",\"name\":\"Unknown or undetermined\"}}"
      # bib request: send token in header
      stub_request(:get, "https://sandbox.iii.com/iii/sierra-api/v2/bibs/1069105").
        with(:headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Authorization'=>'Bearer A_TOKEN', 'User-Agent'=>'Faraday v0.9.2'}).
        to_return(:status => 200, :body => body, :headers => json_headers)
    end

    it 'sends json data when passed a valid bib num' do
      get :load_bib, rec_num: 'B10691054', format: 'json'
      expect(response).to be_successful
      parsed = JSON.parse(response.body)
      expect(parsed['id']).to eq '1069105'
      expect(parsed['bibLevel']['value']).to eq 'COLLECTION'
    end

    it 'generates a 404 for invalid or missing bib number' do
      get :load_bib, rec_num: '54', format: 'json'
      expect(response.status).to eq(404)
    end

  end

end
