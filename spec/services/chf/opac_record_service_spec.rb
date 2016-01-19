require 'rails_helper'

RSpec.describe CHF::OpacRecordService do

  before do
    json_headers = { "Content-Type" => "application/json;charset=UTF-8" }
    # token body
    body = "{\"access_token\":\"A_TOKEN\",\"token_type\":\"bearer\",\"expires_in\":3600}"
    # token request: credentials in url
    stub_request(:post, "https://MY_KEY:MY_SECRET@sandbox.iii.com/iii/sierra-api/v2/token").
      with(:body => {"grant_type"=>"client_credentials"},
        :headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Content-Type'=>'application/x-www-form-urlencoded', 'User-Agent'=>'Faraday v0.9.2'}).
      to_return(:status => 200, :body => body, :headers => json_headers)
    # bad token request: credentials in url
    body = "{\"code\":113,\"specificCode\":0,\"httpStatus\":401,\"name\":\"Unauthorized\",\"description\":\"Invalid or missing authorization header\"}"
    stub_request(:post, "https://MY_KEY:BAD_SECRET@sandbox.iii.com/iii/sierra-api/v2/token").
      with(:body => {"grant_type"=>"client_credentials"},
        :headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Content-Type'=>'application/x-www-form-urlencoded', 'User-Agent'=>'Faraday v0.9.2'}).
      to_return(:status => 200, :body => body, :headers => json_headers)
    # bib body
    body = "{\"id\":\"1000001\",\"updatedDate\":\"2009-07-06T15:30:13Z\",\"createdDate\":\"2003-05-08T15:55:00Z\",\"deleted\":false,\"suppressed\":false,\"lang\":{\"code\":\"eng\"},\"title\":\"Hey, what's wrong with this one?\",\"author\":\"Wojciechowska, Maia, 1927-\",\"materialType\":{\"code\":\"a\",\"value\":\"Book\"},\"bibLevel\":{\"code\":\"m\",\"value\":\"MONOGRAPH\"},\"publishYear\":1969,\"catalogDate\":\"1990-10-10\",\"country\":{\"code\":\"nyu\",\"name\":\"New York (State)\"}}"
    # bib request: send token in header
    stub_request(:get, "https://sandbox.iii.com/iii/sierra-api/v2/bibs/1000001").
      with(:headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Authorization'=>'Bearer A_TOKEN', 'User-Agent'=>'Faraday v0.9.2'}).
      to_return(:status => 200, :body => body, :headers => json_headers)
  end

  it 'fails to connect with bad credentials' do
    opac = CHF::OpacRecordService.new(api_key: 'MY_KEY', client_secret: 'BAD_SECRET')
    expect { opac.get_bib('1000001') }.to raise_error(CHF::OpacConnectionError)
  end

  it 'gets a bib' do
    opac = CHF::OpacRecordService.new(api_key: 'MY_KEY', client_secret: 'MY_SECRET')
    data = opac.get_bib('1000001')
    expect(data).to be_a Hash
    expect(data['publishYear']).to eq(1969)
  end

end
