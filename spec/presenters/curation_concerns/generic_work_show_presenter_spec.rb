require 'spec_helper'



describe CurationConcerns::GenericWorkShowPresenter do
  let(:request) { double }

  let(:ability) { nil }
  let(:presenter) { described_class.new(solr_document, ability, request) }


  describe "#representative_file_id" do
    let(:solr_document) { SolrDocument.new(work.to_solr) }
    let(:ability) { double "Ability" }
    let(:work) do
      FactoryGirl.create(:generic_work).tap do |w|
        w.ordered_members << fileset
        w.ordered_members << fileset2
        w.representative = fileset2
        w.thumbnail = fileset2
        w.save
      end
    end
    let(:fileset) { FactoryGirl.create(:file_set, title: ["adventure_time.txt"], content: StringIO.new("Algebraic!")) }
    let(:fileset2) { FactoryGirl.create(:file_set, title: ["adventure_time_2.txt"], content: StringIO.new("Mathematical!")) }

    it "returns representative fileset's original file id" do
      expect(presenter.representative_file_id).to be_a String
      expect(presenter.representative_file_id).to eq fileset2.original_file.id
    end
  end

  describe "structured dates" do
    let(:dates_of_work_models) { [DateOfWork.new(start: "1901", finish: "1910", start_qualifier: "circa")] }
    let(:solr_document) { SolrDocument.new(work.to_solr) }
    let(:work) do
      FactoryGirl.build(:generic_work, title: ["work"],
        dates_of_work: dates_of_work_models
      )
    end
    it "can rehydrate DateOfWork objects" do
      expect(presenter.date_of_work_models.collect {|m| m.to_json(except: :id) }).to eq(dates_of_work_models.collect {|m| m.to_json(except: :id) })
      expect(presenter.date_of_work_models.all? {|m| m.readonly? }).to be true
    end
  end

  describe "display dates" do
    let(:dates_of_work_models) { date_array }
    let(:solr_document) { SolrDocument.new(work.to_solr) }
    let(:work) do
      FactoryGirl.build(:generic_work, title: ["work"],
        dates_of_work: dates_of_work_models
      )
    end
    it 'correctly displays the date strings given a set of date objects' do
      # see methods "correct_results" and "date_array"
      # at the end of this file for the data.
      the_display_dates = presenter.display_dates
      expected_dates = correct_results
      correct_results.each_with_index.map { |x,i| expect(expected_dates[i]).to eq x }
    end
  end


  describe "#viewable_member_presenters" do
    let(:public_work_with_one_file) do
      work = FactoryGirl.build(:work, visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC)
      work.ordered_members << FactoryGirl.create(:file_set, visibility: file_visibility)
      work.save!
      work
    end

    let(:solr_document) { SolrDocument.new(public_work_with_one_file.to_solr) }

    describe "with admin user"  do
      let(:user) { FactoryGirl.create(:user, :admin) }
      let(:ability) { Ability.new(user) }

      describe "protected file" do
        let(:file_visibility) { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED }
        it "reveals protected file" do
          expect(presenter.viewable_member_presenters.length).to eq 1
        end
      end

      describe "public file" do
        let(:file_visibility) { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC }
        it "reveals public file" do
          expect(presenter.viewable_member_presenters.length).to eq 1
        end
      end
    end

    describe "with non-logged in user" do
      let(:ability) { Ability.new(nil) }

      describe "protected file" do
        let(:file_visibility) { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED }
        it "does not reveal protected file" do
          expect(presenter.viewable_member_presenters.length).to eq 0
        end
      end

      describe "public file" do
        let(:file_visibility) { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC }
        it "reveals public file" do
          expect(presenter.viewable_member_presenters.length).to eq 1
        end
      end
    end
  end
end

def date_array
  data = [
    ["1800",            "",             "",          "",       ""           ],
    [nil,               nil,           nil,         nil,      nil           ],
    [nil,               nil,           nil,         nil,      "circa"       ],
    ["1912",            "",            "decade",    "",       ""            ],
    ["1780",            "",            "decade",    "",       ""            ],
    ["way back when",   "",            "decade",    "",       ""            ],
    ["1912",            "",            "century",   "",       ""            ],
    ["1780",            "",            "century",   "",       ""            ],
    ["way back when",   "",            "century",   "",       ""            ],
    ["1700",            "",            "century",   "",       ""            ],
    ["the end of time", "",            "after",     "",       "For real!"   ],
    ["the end of time", "",            "circa",     "",       ""            ],
    ["1800",            "1900",        "century",   "",       "Note 1"      ],
    ["1800",            "1900",        "century",   "",       "Note 2"      ],
    ["1929-01-02",      "1929-01-03",  "circa",     "before", "Note 3"      ],
    ["1872",            "1929-01-03",  "after",     "before", "Note 4"      ],
    ["1920",            "1928-11",     "decade",    "",       "Note 5"      ],
  ]
  data.collect { |d| DateOfWork.new(
    start:           d[0],    finish:           d[1],
    start_qualifier: d[2],    finish_qualifier: d[3],   note: d[4])}
end

def correct_results
  [
    "1800",
    "",
    " (circa)",
    "Decade starting 1912",
    "1780s",
    "Decade starting way back when",
    "Century starting 1912",
    "Century starting 1780",
    "Century starting way back when",
    "1700s",
    "After the end of time (For real!)",
    "Circa the end of time",
    "1800s – 1900 (Note 1)",
    "1800s – 1900 (Note 2)",
    "Circa 1929-Jan-02 – before 1929-Jan-03 (Note 3)",
    "After 1872 – before 1929-Jan-03 (Note 4)",
    "1920s – 1928-Nov (Note 5)"
  ]
end