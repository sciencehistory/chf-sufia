require 'rails_helper'

describe RiiifHelper do
  def riiif_info_url (riiif_file_id)
    path = riiif.info_path(riiif_file_id, locale: nil)
    if CHF::Env.lookup(:public_riiif_url)
      return Addressable::URI.join(CHF::Env.lookup(:public_riiif_url), path).to_s
    else
      return path
    end
  end
  describe "#riiif_info_url" do
    context "riiif uses localhost" do
      it "provides relative path" do
        allow(CHF::Env).to receive(:lookup).with(:public_riiif_url).and_return(nil)
        expect(helper.riiif_info_url('file_id')).to eq "/image-service/file_id/info.json"
      end
    end

    context "riiif configured for remote box" do
      it "provides full url" do
        allow(CHF::Env).to receive(:lookup).with(:public_riiif_url).and_return('//example.com')
        expect(helper.riiif_info_url('file_id')).to eq "//example.com/image-service/file_id/info.json"
      end
    end
  end
end
