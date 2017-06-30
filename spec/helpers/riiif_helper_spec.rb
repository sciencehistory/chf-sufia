require 'rails_helper'

describe RiiifHelper do
  let(:ability) { double }
  let(:presenter) do
    CurationConcerns::GenericWorkShowPresenter.new(solr_document, ability)
  end
  let(:solr_document) { SolrDocument.new(work.to_solr) }
  let(:work) { FactoryGirl.build(:work) }

  describe "#riiif_info_url" do
    before do
      allow(presenter).to receive(:riiif_file_id).and_return('file_id')
    end

    context "riiif uses localhost" do
      it "provides relative path" do
        allow(CHF::Env).to receive(:lookup).with(:public_riiif_url).and_return(nil)
        expect(helper.riiif_info_url(presenter)).to eq "/image-service/file_id/info.json"
      end
    end

    context "riiif configured for remote box" do
      context "correct config supplied" do
        it "provides full url" do
          allow(CHF::Env).to receive(:lookup).with(:public_riiif_url).and_return('//example.com')
          expect(helper.riiif_info_url(presenter)).to eq "//example.com/image-service/file_id/info.json"
        end
      end
      context "bare host supplied" do
        it "raises" do
          allow(CHF::Env).to receive(:lookup).with(:public_riiif_url).and_return('example.com')
          expect{ helper.riiif_info_url(presenter) }.to raise_error(RuntimeError)
        end
      end
      context "the presenter can't find a file" do
        # e.g. the work has no members
        it "provides a local path to a default thumb" do
        end
      end
    end
  end

end
