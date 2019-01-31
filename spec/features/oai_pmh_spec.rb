require 'rails_helper'

# Because creating real data is so slow, and feature tests pretty slow too,
# we try to do everything in one test, even though that's not great test design.
RSpec.feature "OAI-PMH feed", js: false do
  before do
    # no fits on travis
    allow_any_instance_of(CharacterizeJob).to receive(:perform).and_return(nil)
  end

  let!(:work) { FactoryGirl.create(:public_work, :with_complete_metadata, :real_public_image) }
  let!(:collection) { FactoryGirl.create(:public_collection) }
  let(:oai_pmh_xsd_path) { Rails.root + "spec/fixtures/xsd/OAI-PMH.xsd" }

  it "renders feed with just work" do
    visit(oai_pmh_oai_path(verb: "ListRecords", metadataPrefix: "oai_dc"))

    expect(page.status_code).to eq 200

    # parse strict, so we get an exception if it's not well-formed XML
    xml = Nokogiri::XML(page.body) { |config| config.strict }

    # validate XSD
    schema = Nokogiri::XML::Schema(File.read(oai_pmh_xsd_path))
    errors = schema.validate(xml)
    # PA Digital is at present asking for a dc:identifier.thumbnail element which
    # fails validation.
    expect(
      errors.count == 0 ||
      ( errors.count == 1 && errors.first.message.include?("identifier.thumbnail': This element is not expected.") )
    )

    # includes one item, which is the work, not the collection
    records = xml.xpath("//oai:record", oai: "http://www.openarchives.org/OAI/2.0/")
    expect(records.count).to eq (1)
    dc_contributors = xml.xpath("//dc:contributor", dc:"http://purl.org/dc/elements/1.1/").children.map(&:to_s)
    # dc:contributors should include both the plain vanilla "contributor" but also the "editor".
    expect(dc_contributors.map).to include("contributorcontributor", "G. Henle Verlag", "John Lennon")
    record_id = records.first.at_xpath("./oai:header/oai:identifier", oai: "http://www.openarchives.org/OAI/2.0/")
    expect(record_id.text).to eq("oai:sciencehistoryorg:#{work.id}")
  end
end
