require 'rails_helper'


def my_count(x)
  x.sum { |x| 1 }
end

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
    "project" => ["Nanotechnology", "Mass Spectrometry"],
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
    "dates" => [
      {
        "start" => "1200",
        "start_qualifier" => "century"
      },
      {
        "start" => "2003",
        "finish" => "2015"
      }
    ],
    "inscriptions" => [
      {
        "location" => "place",
        "text" => "stuff",
        "display_label" => "(place) \"stuff\""
      },
      {
        "location" => "chapter 7",
        "text" => "words",
        "display_label" => "(chapter 7) \"words\""
      }
    ],
    "additional_credits" => [
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
    ]
    }
  end #let :expected_export_hash

  it "exports" do
    work_2 = GenericWork.find(work.id)

    puts my_count(work_2.additional_credit) # 2
    puts my_count(work  .additional_credit) # 4

    actual_hash = GenericWorkExporter.new(work_2).to_hash
    %w(id depositor access_control_id date_of_work_ids inscription_ids additional_credit_ids).each do |k|
      actual_hash.delete(k)
      expected_export_hash.delete(k)
    end

    # Travis hack:
    # For whatever reason, these two sort lines are only needed to get Travis to pass...
    actual_hash['project'].sort!
    expected_export_hash['project'].sort!
    # end Travis hack

    byebug unless actual_hash == expected_export_hash

    expect(actual_hash).to eq expected_export_hash
    end
end # describe


