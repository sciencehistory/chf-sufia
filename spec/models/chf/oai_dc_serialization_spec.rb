require 'spec_helper'

describe CHF::OaiDcSerialization do
  let(:work) { FactoryGirl.create(:generic_work, :with_complete_metadata, :real_public_image)}
  # not sure this is actually right...
  let(:solr_document) { SolrDocument.new(work.to_solr) }
  let(:instance) { CHF::OaiDcSerialization.new(solr_document)}

  let(:mocked_thumb_url) { "http://example.com/thumbnail.jpg"}
  before do
    # cheesy fragile way to mock thumbnail urls even though we don't have it set up in test
    allow_any_instance_of(CHF::LegacyAssetUrlService).to receive(:download_options).and_return([
      {
        option_key: "medium",
        url: mocked_thumb_url
      }
    ])

    # mock to turn off fits characterization, super slow and we don't have it on travis
   allow_any_instance_of(CharacterizeJob).to receive(:perform).and_return(nil)
  end

  it "serializes" do
    xml_str = instance.to_oai_dc

    # is well-formed XML
    xml = Nokogiri::XML(xml_str) { |config| config.strict }

    container = xml.at_xpath("./oai_dc:dc")
    expect(container).to be_present

    # PA digital wants both URL and thumbnail URL in dc:identifiers
    dc_identifiers = container.xpath("./dc:identifier").collect(&:text)
    expect(dc_identifiers).to include "#{CHF::Env.lookup(:app_url_base)}/works/#{work.id}"
    expect(dc_identifiers).to include mocked_thumb_url

    expect(container.at_xpath("./dc:title").text).to eq work.title.first
    expect(container.at_xpath("./dc:rights").text).to eq work.rights.first
    expect(container.at_xpath("./dc:creator").text).to eq work.author.first
    expect(container.at_xpath("./dc:description").text).to eq work.description.first
    expect(container.at_xpath("./dc:format").text).to eq work.file_sets.first.mime_type
    expect(container.at_xpath("./dc:language").text).to eq work.language.first
    expect(container.at_xpath("./dc:subject").text).to eq work.subject.first
    expect(container.at_xpath("./dc:type").text).to eq work.resource_type.first
    expect(container.at_xpath("./dpla:originalRecord").text).to eq "#{CHF::Env.lookup(:app_url_base)}/works/#{work.id}"
    expect(container.at_xpath("./edm:rights").text).to eq work.rights.first
    expect(container.at_xpath("./edm:hasType").text).to eq work.genre_string.first.downcase
    expect(container.at_xpath("./edm:object").text).to eq Rails.application.routes.url_helpers.download_url(work.representative_id)
    expect(container.at_xpath("./edm:preview").text).to eq mocked_thumb_url
  end

end
