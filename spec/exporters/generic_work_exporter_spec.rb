require 'rails_helper'

RSpec.describe GenericWorkExporter do
  let (:work) do
    FactoryGirl.create(:generic_work, dates_of_work: []).tap do |w|
      w.physical_container = "b2000|f3|v4|p5|g234|sMS 13"
      w.date_of_work_attributes = [{start: "2003", finish: "2015"}, {start:'1200', start_qualifier:'century'}]
      w.inscription_attributes = [{location: "chapter 7", text: "words"}, {location: "place", text: "stuff"}]
      w.additional_credit_attributes = [{role: "photographer", name: "Puffins"}, {role: "photographer", name: "Squirrels"}]
      w.author = ["Bruce McMillan"]
      w.photographer = ["Bruce McMillan"]
      w.publisher = ["publishing house"]
      w.editor = ["the editor"]
      w.attributed_to = ["presumptive author"]
      w.engraver = ["engraving professional"]
      w.project = ['Mass Spectrometry', 'Nanotechnology']
      w.save
    end # tap do
  end # let work


  # TODO: investigate why dates and inscriptions appear to contain duplicate material.
  let (:expected_export_hash) do {
    "id" => "st74cq441",
    "depositor" => "user1_72e0@example.com",
    "title" => ["Test title"],
    "attributed_to" => ["presumptive author"],
    "author" => ["Bruce McMillan"],
    "editor" => ["the editor"],
    "engraver" => ["engraving professional"],
    "photographer" => ["Bruce McMillan"],
    "publisher" => ["publishing house"],
    "credit_line" => ["Courtesy of Science History Institute"],
    "project" => ["Mass Spectrometry", "Nanotechnology"],
    "physical_container" => "b2000|f3|v4|p5|g234|sMS 13",
    "access_control_id" => "b14df645-5a06-40e8-826a-43579fe6cfed",
    "date_of_work_ids" => ["63f04166-8712-4667-9f33-8ed9c0d68402",
      "ce0b6cef-3ab4-4e88-a9c5-de03c36dc51b"
    ],
    "inscription_ids" => ["cd66f7d8-8db4-461d-93ca-d5304da47763",
      "ba4ea153-7a3e-4525-8332-d4cb061f5ff5"
    ],
    "additional_credit_ids" => ["472a387e-e872-4c36-a9ce-eb3038744f08",
      "9aa815ab-53f4-427a-913f-4c3347f96823"
    ],
    "access_control" => "public",
    "dates" => [{
        "start" => "2003",
        "finish" => "2015"
      },
      {
        "start" => "1200",
        "start_qualifier" => "century"
      },
      {
        "start" => "2003",
        "finish" => "2015"
      },
      {
        "start" => "1200",
        "start_qualifier" => "century"
      }
    ],
    "inscriptions" => [{
        "location" => "chapter 7",
        "text" => "words",
        "display_label" => "(chapter 7) \"words\""
      },
      {
        "location" => "place",
        "text" => "stuff",
        "display_label" => "(place) \"stuff\""
      },
      {
        "location" => "chapter 7",
        "text" => "words",
        "display_label" => "(chapter 7) \"words\""
      },
      {
        "location" => "place",
        "text" => "stuff",
        "display_label" => "(place) \"stuff\""
      }
    ],
    "additional_credits" => [{
        "role" => "photographer",
        "name" => "Puffins",
        "display_label" => "Photographed by Puffins"
      },
      {
        "role" => "photographer",
        "name" => "Squirrels",
        "display_label" => "Photographed by Squirrels"
      },
      {
        "role" => "photographer",
        "name" => "Puffins",
        "display_label" => "Photographed by Puffins"
      },
      {
        "role" => "photographer",
        "name" => "Squirrels",
        "display_label" => "Photographed by Squirrels"
      }
    ]
    }
  end #let :expected_export_hash

  it "exports" do
    x = GenericWorkExporter.new(work)
    actual_hash = x.to_hash
    %w(id depositor access_control_id date_of_work_ids inscription_ids additional_credit_ids).each do |k|
      actual_hash.delete(k)
      expected_export_hash.delete(k)
    end
    expect(actual_hash).to eq expected_export_hash
  end


  # context "public work" do
  #   let(:metadata) do
  #     {
  #       "id"=>"8049g504g",
  #       "head" => [
  #         "#<ActiveTriples::Resource:0x0000558a2682fa68>"
  #       ],
  #       "tail" => [
  #         "#<ActiveTriples::Resource:0x0000558a26826030>"
  #       ],
  #       "depositor"=> "njoniec@sciencehistory.org",
  #       "title" => [
  #         "Adulterations of food; with short processes for their detection."
  #       ],
  #       "date_uploaded"=> "2019-02-08T20:45:54+00:00",
  #       "date_modified"=> "2019-02-08T20:49:43+00:00",
  #       "state" => "#<ActiveTriples::Resource:0x0000558a2d321088>",
  #       "part_of" => [
  #         "#<ActiveTriples::Resource:0x0000558a2681aff0>"
  #       ],
  #       "identifier" => [
  #         "bib-b1075796"
  #       ],
  #       "author" => [
  #         "Atcherley, Rowland J."
  #       ],
  #       "credit_line" => [
  #         "Courtesy of Science History Institute"
  #       ],
  #       "division" => "",
  #       "file_creator" =>  "",
  #       "physical_container" =>  "",
  #       "rights_holder" =>  "",
  #       "access_control_id" =>  "90cb04df-61a7-4d61-84e2-130fc7ddbee3",
  #       "access_control" => "public",
  #       "representative_id" =>  "2v23vv55g",
  #       "thumbnail_id" =>  "2v23vv55g",
  #       "admin_set_id" =>  "admin_set/default",
  #       "child_ids" =>  [
  #         "kp78gh433",
  #         "1v53jz06w",
  #         "nk322f35j",
  #         "0r9674786",
  #         "6q182m18c",
  #         "1831cm25h",
  #         "8623hz81w"
  #       ]
  #     }
  #   end

  #   it "imports as published" do
  #     generic_work_importer.import
  #     new_work = Work.first

  #     expect(new_work.published?).to be(true)
  #   end

  #   describe "with existing item" do
  #     let!(:existing_item) { FactoryBot.create(:work,
  #       friendlier_id: metadata["id"],
  #       title: "old title",
  #       external_id: { category: "object", value: "old_id"},
  #       published: false)}

  #     it "imports and updates data" do
  #       generic_work_importer.import

  #       expect(Work.where(friendlier_id: metadata["id"]).count).to eq(1)
  #       item = Work.find_by_friendlier_id!(metadata["id"])

  #       expect(item.title).to eq "Adulterations of food; with short processes for their detection."
  #       expect(item.published?).to be(true)
  #       expect(item.external_id).to eq([Work::ExternalId.new(category: "bib", value: "b1075796")])
  #     end
  #   end
  # end
end # describe
