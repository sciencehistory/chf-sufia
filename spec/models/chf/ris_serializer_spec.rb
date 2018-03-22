require 'spec_helper'

describe CHF::RisSerializer do
  let(:work) do
    FactoryGirl.build(:public_work,
      id: "MOCK_ID",
      dates_of_work: nil,
      creator_of_work: ["Hawes, R. C."],
      publisher: ["Sackett, Israel, 1809-1880"],
      place_of_publication: ["New York (State)--New York"],
      description: ['This is an abstract'],
      subject: ['subject1', 'subject2'],
      language: ['English', 'German']
    )
  end
  let(:presenter) { CurationConcerns::GenericWorkShowPresenter.new(SolrDocument.new(work.to_solr), Ability.new(nil)) }
  let(:serializer) { CHF::RisSerializer.new(presenter) }
  let(:serialized) { serializer.to_ris }
  let(:serialized_fields) do
    serialized.split(CHF::RisSerializer::RIS_LINE_END).collect do |line|
      (tag, value) = line.split("  - ")
      [tag, value || nil]
    end.to_h
  end

  it "serializes" do
    expect(serialized).to be_present
  end

  it "serializes as expected" do
    expect(serialized_fields["TY"]).to be_present

    expect(serialized_fields["DB"]).to eq "Science History Institute"
    expect(serialized_fields["DP"]).to eq "Science History Institute"
    expect(serialized_fields["M2"]).to eq "Courtesy of Science History Institute."
    expect(serialized_fields["TI"]).to eq "Test title"
    expect(serialized_fields["AU"]).to eq "Hawes, R. C."
    expect(serialized_fields["PB"]).to eq "Israel Sackett"
    expect(serialized_fields["CY"]).to eq "New York, New York"
    expect(serialized_fields["UR"]).to eq "https://digital.sciencehistory.org/works/MOCK_ID"
    expect(serialized_fields["AB"]).to eq "This is an abstract"
    expect(serialized_fields["KW"]).to eq "subject2"
    expect(serialized_fields["LA"]).to eq "English, German"
  end

  describe "complex archival work" do
    let(:collection) { FactoryGirl.build(:collection, title: ["Collection Title"]) }
    let(:parent_work) { FactoryGirl.build(:work, title: ["parent_work"]) }
    let(:work) do
      FactoryGirl.build(:public_work,
        title: ["Work title"],
        creator_of_work: ["Hawes, R. C."],
        publisher: ["Sackett, Israel, 1809-1880"],
        place_of_publication: ["New York (State)--New York"],
        description: ['This is an abstract'],
        subject: ['subject1', 'subject2'],
        language: ['English', 'German'],
        division: "Archives",
        series_arrangement: ["Sub-series 2. Advertisements", "Series VIII. Clippings and Advertisements"],
        physical_container: "b49|f14",
        dates_of_work: [DateOfWork.new(start: "1916-05-04")],
        rights: ["http://rightsstatements.org/vocab/InC-RUU/1.0/"]
      )
    end
    let(:serializer) { CHF::RisSerializer.new(presenter, collection: collection, parent_work: parent_work) }

    it "serializes as expected" do
      expect(serialized_fields["DB"]).to eq "Science History Institute"
      expect(serialized_fields["DP"]).to eq "Science History Institute"
      expect(serialized_fields["AV"]).to eq "Collection Title, Box 49, Folder 14"
      expect(serialized_fields["TI"]).to eq "Work title"
      expect(serialized_fields["T2"]).to eq "parent_work"
      expect(serialized_fields["YR"]).to eq "1916"
      expect(serialized_fields["DA"]).to eq "1916/05/04/"
      expect(serialized_fields["M2"]).to eq "Courtesy of Science History Institute.  Rights: In Copyright - Rights-holder(s) Unlocatable or Unidentifiable"
    end
  end

end
