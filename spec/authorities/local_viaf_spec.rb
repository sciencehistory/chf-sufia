require 'rails_helper'

RSpec.describe LocalViaf do

  # api call
  describe "query url" do
    let :authority do
      LocalViaf.new
    end

    it "is correctly formed" do
      url = 'http://viaf.org/viaf/search?query=local.personalNames%20=%20%22bowman,%20robert%22&recordSchema=http%3A%2F%2Fviaf.org%2FBriefVIAFCluster&maximumRecords=20&startRecord=1&sortKeys=holdingscount&httpAccept=text/xml'
      expect(authority.build_query_url('personalNames', "bowman, robert")).to eq(url)
    end
  end

  describe "search result" do
    let :authority do
      LocalViaf.new
    end

    context "when query is blank" do
      # server returns results but no results header
      let :results do
        stub_request(:get, "http://viaf.org/viaf/search?httpAccept=text/xml&maximumRecords=20&query=local.personalNames%20=%20%22%22&recordSchema=http://viaf.org/BriefVIAFCluster&sortKeys=holdingscount&startRecord=1").
          with(:headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip, deflate'}).
          to_return(:body => webmock_fixture("viaf-blank.xml"), :status => 200, :headers => {})
        authority.search_subauthority('personalNames', "")
       end
      it "returns an empty array" do
        expect(results).to eq([])
      end
    end

    context "with results" do
      let :results do
        stub_request(:get, "http://viaf.org/viaf/search?httpAccept=text/xml&maximumRecords=20&query=local.personalNames%20=%20%22bowman,%20robert%22&recordSchema=http://viaf.org/BriefVIAFCluster&sortKeys=holdingscount&startRecord=1").
          with(:headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip, deflate'}).
          to_return(:body => webmock_fixture("viaf-bowman.xml"), :status => 200, :headers => {})
        authority.search_subauthority('personalNames', "bowman, robert")
      end
      it "is correctly parsed" do
        expect(results.count).to eq(20)
        expect(results.first[:id]).to eq('10018740')
        expect(results.first[:label]).to eq('Bowman, Robert M. J. (Robert Middlename James) (LC)')
        expect(results.first[:value]).to eq('Bowman, Robert M. J. (Robert Middlename James)')
      end
    end
  end

end
