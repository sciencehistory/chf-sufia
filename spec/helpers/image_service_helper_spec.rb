require 'rails_helper'

describe ImageServiceHelper do
  describe "#iiif_info_url" do
    before do
      allow(CHF::Env).to receive(:lookup).with(:iiif_public_url).and_return('http://localhost:3000/image-service')
    end

    context "info.json" do
      it "works with localhost/port" do
        expect(helper.iiif_info_url('file_id')).to eq "http://localhost:3000/image-service/file_id/info.json"
      end

      it "works with schemaless host" do
        allow(CHF::Env).to receive(:lookup).with(:iiif_public_url).and_return('//localhost:3000/image-service')
        expect(helper.iiif_info_url('file_id')).to eq "//localhost:3000/image-service/file_id/info.json"
      end

      it "escapes id" do
        expect(helper.iiif_info_url('path/file_id')).to eq "http://localhost:3000/image-service/#{CGI.escape 'path/file_id'}/info.json"
      end

      context "with a cantaloupe host" do
        before do
          allow(CHF::Env).to receive(:lookup).with(:iiif_public_url).and_return('http://example.com:8182/iiif/2')
        end
        it "works when no trailing slash" do
          expect(helper.iiif_info_url('file_id')).to eq "http://example.com:8182/iiif/2/file_id/info.json"
        end
        it "works when yes trailing slash" do
          expect(helper.iiif_info_url('file_id')).to eq "http://example.com:8182/iiif/2/file_id/info.json"
        end
      end

      it "raises on bare host" do
        allow(CHF::Env).to receive(:lookup).with(:iiif_public_url).and_return('example.com')
        expect{ helper.iiif_info_url('file_id') }.to raise_error(RuntimeError)
      end
    end
  end

  describe "#iiif_image_url" do
    describe "with base url with path" do
      let(:file_id) { "test_file_id/something" }
      before do
        allow(CHF::Env).to receive(:lookup).with(:iiif_public_url).and_return('http://localhost:3000/image-service')
      end

      it "joins properly" do
        expect( helper.iiif_image_url(file_id)).to eq("http://localhost:3000/image-service/test_file_id%2Fsomething/full/full/0/default.jpg")
      end
    end
  end

end
