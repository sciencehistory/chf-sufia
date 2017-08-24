require 'rails_helper'

describe ImageServiceHelper do
  let(:file_id) { "path/totally_a_file_id" }
  let(:escaped_file_id) { CGI.escape file_id }
  let(:mock_member_presenter) {
      mock_model('MockMemberPresenter',
        representative_file_id: file_id,
        representative_id: "maybe_a_work",
        representative_width: "100",
        representative_height: "100",
        representative_checksum: "adfadfadfadfadfasdf")
  }


  describe "#tile_source_url" do
    before do
      allow(CHF::Env).to receive(:lookup).with(:iiif_public_url).and_return('http://localhost:3000/image-service')
      allow(CHF::Env).to receive(:lookup).with(:image_server_on_viewer).and_return("iiif")
    end

    context "info.json" do
      it "works with localhost/port" do
        expect(helper.tile_source_url(mock_member_presenter)).to eq "http://localhost:3000/image-service/#{escaped_file_id}/info.json"
      end

      it "works with schemaless host" do
        allow(CHF::Env).to receive(:lookup).with(:iiif_public_url).and_return('//localhost:3000/image-service')
        expect(helper.tile_source_url(mock_member_presenter)).to eq "//localhost:3000/image-service/#{escaped_file_id}/info.json"
      end


      context "with a cantaloupe host" do
        before do
          allow(CHF::Env).to receive(:lookup).with(:iiif_public_url).and_return('http://example.com:8182/iiif/2')
        end
        it "works when no trailing slash" do
          expect(helper.tile_source_url(mock_member_presenter)).to eq "http://example.com:8182/iiif/2/#{escaped_file_id}/info.json"
        end
        it "works when yes trailing slash" do
          expect(helper.tile_source_url(mock_member_presenter)).to eq "http://example.com:8182/iiif/2/#{escaped_file_id}/info.json"
        end
      end

      it "raises on bare host" do
        allow(CHF::Env).to receive(:lookup).with(:iiif_public_url).and_return('example.com')
        expect{ helper.tile_source_url(mock_member_presenter) }.to raise_error(RuntimeError)
      end
    end
  end

  describe "#member_image_tag" do
    let(:parent_id) { "parent_id" }
    describe "with base url with path" do
      before do
        allow(CHF::Env).to receive(:lookup).with(:iiif_public_url).and_return('http://localhost:3000/image-service')
        allow(CHF::Env).to receive(:lookup).with(:image_server_on_show_page).and_return("iiif")
      end

      let(:html) { Nokogiri::HTML.fragment(helper.member_image_tag(member: mock_member_presenter, parent_id: parent_id)) }
      let(:img) { html.at_css("img") }

      it "joins properly" do
        expect(img['src']).to eq("http://localhost:3000/image-service/#{escaped_file_id}/full/#{ImageServiceHelper::BASE_WIDTHS[:standard]},/0/default.jpg")
      end
    end
  end

end
