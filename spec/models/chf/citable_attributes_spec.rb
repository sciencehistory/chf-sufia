require 'spec_helper'

describe CHF::CitableAttributes do
  let(:collection) { nil }
  let(:presenter) { CurationConcerns::GenericWorkShowPresenter.new(SolrDocument.new(work.to_solr), Ability.new(nil)) }
  let(:citable_attributes) { CHF::CitableAttributes.new(presenter, collection: collection)}

  describe "standard treatment" do
    let(:work) { FactoryGirl.build(:generic_work, dates_of_work: nil)}

    describe "authors" do
      describe "inverted without dates" do
        before do
          work.creator_of_work = ["Allen, Ken"]
        end
        it "parses" do
          expect(citable_attributes.authors).to include(CiteProc::Name.new(family: "Allen", given: "Ken"))
        end
      end

      describe "inverted without dates, initials" do
        before do
          work.creator_of_work = ["Hawes, R. C."]
        end
        it "parses" do
          expect(citable_attributes.authors).to include(CiteProc::Name.new(family: "Hawes", given: "R. C."))
        end
      end

      describe "inverted with dates" do
        before do
          work.creator_of_work = ["Sackett, Israel, 1809-1880"]
        end
        it "parses" do
          expect(citable_attributes.authors).to include(CiteProc::Name.new(family: "Sackett", given: "Israel"))
        end
      end

      describe "corporate name" do
        before do
          work.creator_of_work = ["Beckman Instruments, inc."]
        end
        it "parses" do
          expect(citable_attributes.authors).to include(CiteProc::Name.new(literal: "Beckman Instruments"))
        end
      end

      describe "corporate name that looks kinda like a personal name" do
        before do
          work.creator_of_work = ["Simpkin, Mashall, and Co."]
        end
        it "parses as literal" do
          expect(citable_attributes.authors).to include(CiteProc::Name.new(literal: "Simpkin, Mashall, and Co."))
        end
      end

      describe "creators preferred over other makers" do
        before do
          work.creator_of_work = ["Creator, John", "Creator, Sue"]
          work.author = ["Author, Bill", "Author, Jane"]
          work.contributor = ["Contributor, Jaime"]
        end
        it "parses" do
          expect(citable_attributes.authors.length).to eq(2)
          expect(citable_attributes.authors).to include(CiteProc::Name.new(family: "Creator", given: "John"))
          expect(citable_attributes.authors).to include(CiteProc::Name.new(family: "Creator", given: "Sue"))
        end
      end

      describe "authors used if no creators" do
        before do
          work.author = ["Author, Bill", "Author, Jane"]
          work.contributor = ["Contributor, Jaime"]
        end
        it "parses" do
          expect(citable_attributes.authors.length).to eq(2)
          expect(citable_attributes.authors).to include(CiteProc::Name.new(family: "Author", given: "Bill"))
          expect(citable_attributes.authors).to include(CiteProc::Name.new(family: "Author", given: "Jane"))
        end
      end

      describe "this one" do
        before do
          work.creator_of_work = ["Chemists' Club (New York, N.Y.)"]
        end
        it "parses" do
          expect(citable_attributes.authors).to include(CiteProc::Name.new(literal: "Chemists' Club (New York, N.Y.)"))
        end
      end

      describe "all sorts of dates" do
        {
          'Backus, Standish, 1910-1989' => {family: "Backus", given: "Standish"},
          "Van Sompel, Pieter 1600?-1643?" => {family: "Van Sompel", given: "Pieter"}, # from work id qj72p783g
          "Antonius, Wilhelm, -1611" => {family: "Antonius", given: "Wilhelm"}, # from work id vd66vz91p
          "Ramelli, Agostino, 1531-approximately 1600" => {family: "Ramelli", given: "Agostino"},
          "Siemienowicz, Kazimierz, -1651?" => {family: "Siemienowicz", given: "Kazimierz"},
          "Bonus, Petrus, active 1323-1330" => {family: "Bonus", given: "Petrus"},
          "Faber, John, 1695?-1756" => {family: "Faber", given: "John"}

        }.each do |str, formatted|
          describe str do
            before do
              work.creator_of_work = [str]
            end
            it "parses" do
              expect(citable_attributes.authors).to include(CiteProc::Name.new(formatted))
            end
          end
        end
      end
    end

    describe "publisher" do
      describe "with inverted form with dates" do
        before do
          work.publisher = ["Sackett, Israel, 1809-1880"]
        end
        it "uses in direct form" do
          expect(citable_attributes.publisher).to eq("Israel Sackett")
        end
      end

      describe "with corporate name" do
        before do
          work.publisher = ["Beckman Instruments, inc."]
        end
        it "uses direct corporate name" do
          expect(citable_attributes.publisher).to eq("Beckman Instruments")
        end
      end
    end

    describe "publisher place" do
      before do
        work.place_of_publication = ["New York (State)--New York"]
      end
      it "uses directly ordered name" do
        expect(citable_attributes.publisher_place).to eq("New York, New York")
      end
    end

    describe "medium" do
      before do
        work.medium = ["Vellum", "Leather"]
      end
      it "joins" do
        # gah, order is indeterminate from fedora. :(
        expect(citable_attributes.medium.split(", ")).to contain_exactly('vellum', 'leather')
      end
    end

    describe "archival location" do
      describe "Non-archives" do
        before do
          work.division = "Library"
          work.series_arrangement = ["Subseries B", "Series XIV"]
          work.physical_container = "v8|p2|g100"
        end
        it "ignores" do
          expect(citable_attributes.archive_location).to be_nil
        end
      end
      describe "Archives" do
        let(:collection) { CHF::CollectionShowPresenter.new(SolrDocument.new(title_tesim: ["Collection Name"]), Ability.new(nil)) }
        before do
          work.division = "Archives"
          work.series_arrangement = ["Subseries B", "Series XIV"]
          work.physical_container = "b56|f47"
        end
        it "includes collection box and folder but not series" do
          expect(citable_attributes.archive_location).to eq("Collection Name, Box 56, Folder 47")
        end
      end
    end

    describe "dates" do
      before do
        allow(work).to receive(:date_of_work).and_return(date_of_work)
      end
      describe "one date year-only" do
        let(:date_of_work) { [DateOfWork.new(start: "1916", finish: "", start_qualifier: "", finish_qualifier: "", note: "")] }
        it "gets one date with year only" do
          expect(citable_attributes.date).to eq(CiteProc::Date.new([1916]))
        end
      end
      describe "one date all parts" do
        let(:date_of_work) { [DateOfWork.new(start: "1916/04/12")] }
        it "gets all parts" do
          expect(citable_attributes.date).to eq(CiteProc::Date.new([1916, 4, 12]))
        end
      end
      describe "start and finish date just years" do
        let(:date_of_work) { [DateOfWork.new(start: "1916", finish: "1920")] }
        it ("gets a CiteProc::Date range") do
          expect(citable_attributes.date).to eq(CiteProc::Date.new([[1916], [1920]]))
        end
      end
      describe "Multiple dates with start and finish" do
        let(:date_of_work) do
          [
            DateOfWork.new(id: SecureRandom.uuid, start: "1901", start_qualifier: "after"), # right now ignores 'after'
            DateOfWork.new(id: SecureRandom.uuid, start: "1916", finish: "1920"),
            DateOfWork.new(id: SecureRandom.uuid, start: "1940", finish: "1960"),
            DateOfWork.new(id: SecureRandom.uuid, start: "1910"),
            DateOfWork.new(id: SecureRandom.uuid, finish: "2000", finish_qualifier: "before")  # right now ignores 'before'
          ]
        end

        it ("gets the right CiteProc::Date range") do
          expect(citable_attributes.date).to eq(CiteProc::Date.new([[1910], [1960]]))
          expect(citable_attributes.issued_date_csl).to eq ({"date-parts"=>[[1910], [1960]], "literal"=>"1910–1960"})
        end
      end

      describe "decade" do
        let(:date_of_work) do
          [DateOfWork.new("start": "1900", start_qualifier: "decade")]
        end
        it ("gets a decade range") do
          expect(citable_attributes.date).to eq(CiteProc::Date.new([[1900], [1909]]))
        end
      end

      describe "century" do
        let(:date_of_work) do
          [DateOfWork.new("start": "1900", start_qualifier: "century")]
        end
        it ("gets a century range") do
          expect(citable_attributes.date).to eq(CiteProc::Date.new([[1900], [1999]]))
        end
      end

      describe "circa" do
        let(:date_of_work) do
          [DateOfWork.new("start": "1947", start_qualifier: "circa")]
        end
        it ("sets citeproc date as circa") do
          date = citable_attributes.date
          # citeproc equality isn't actually taking circa into account, so we test separately too
          expect(date.uncertain?).to be true
          expect(citable_attributes.date).to eq(CiteProc::Date.new([[1947]]).tap {|d| d.uncertain! })
          expect(citable_attributes.issued_date_csl).to eq({"date-parts" => [[1947]], "circa"=>true, "literal" => "circa 1947"})
        end
      end

      describe "no dates" do
        let(:date_of_work) { [] }
        it "has no date" do
          expect(citable_attributes.date).to eq(nil)
        end
      end

      describe "undated date" do
        let(:date_of_work) { [DateOfWork.new(start: "", finish: "", start_qualifier: "Undated", finish_qualifier: "", note: "")] }
        it "has no date" do
          expect(citable_attributes.date).to eq(nil)
        end
      end
    end

    describe :as_csl do
      describe "barely metadata" do
        let(:work) { FactoryGirl.build(:work, title: ["something"], dates_of_work: nil) }
        it "still creates something" do
          expect(citable_attributes.as_csl_json).to be_kind_of(Hash)
        end
      end

      describe "library with shelfmark" do
        let(:work) {
          FactoryGirl.build(:generic_work,
            title: ["Pretiosa margarita novella"],
            author: ["Bonus, Petrus"],
            resource_type: ["Text"],
            genre_string: ["Rare Books", "Manuscripts"],
            division: "Library",
            physical_container: "sMS 3",
            dates_of_work: nil
          )
        }
        before do
          allow(work).to receive(:date_of_work).and_return([DateOfWork.new(start: "1450", finish: "1480", start_qualifier: "circa")])
          allow(work).to receive(:id).and_return("pn89d712c")
        end

        it "exports CSL we expect" do
          csl_hash = citable_attributes.as_csl_json
          expect(csl_hash[:type]).to eq "manuscript"
          expect(csl_hash[:archive]).to eq "Science History Institute"
          expect(csl_hash[:'archive-place']).to eq "Philadelphia"
          expect(csl_hash[:archive_location]).to eq "MS 3"
        end
      end

      describe "archival" do
        let(:work) {
          # based on https://digital.sciencehistory.org/works/2r36tx526
          FactoryGirl.build(:generic_work,
            title: ["pH means Beckman"],
            creator_of_work: ["Beckman Instruments, inc.", "Charles Bowes Advertising, inc."],
            resource_type: ["Image", "Text"],
            genre_string: ["Advertisements"],
            extent: ["8.5 in. W x 11 in. L"],
            language: ["English"],
            subject: ["Beckman Instruments, inc.", "Scientific apparatus and instruments", "Hydrogen-ion concentration--Measurement--Instruments"],
            division: "Archives",
            dates_of_work: nil,
            series_arrangement: ["Sub-series 2. Advertisements", "Series VIII. Clippings and Advertisements"],
            physical_container: "b49|f14")
        }
        before do
          allow(work).to receive(:date_of_work).and_return([DateOfWork.new(start: "1957")])
          allow(work).to receive(:id).and_return("123456")
        end
        it "exports CSL we expect" do
          csl_hash = citable_attributes.as_csl_json
          expect(csl_hash).to include({
            :type=>"manuscript",
            :title=>"pH means Beckman",
            :id=>"scihist123456",
            :issued => {"date-parts"=>[[1957]]},
            :URL=>"#{CHF::Env.lookup(:app_url_base)}/works/123456",
            :archive=>"Science History Institute",
            :'archive-place'=>"Philadelphia",
            :archive_location=>"Box 49, Folder 14"})
          # fedora is annoyingly order-inconsistent
          expect(csl_hash[:author]).to contain_exactly({"literal"=>"Beckman Instruments"}, {"literal"=>"Charles Bowes Advertising"})
        end
      end
    end
  end

  describe "Special case museum photo" do
    let(:date_uploaded) { DateTime.now }
    let(:work) { FactoryGirl.build(:work,
      division: "Museum",
      resource_type: ["Physical Object"],
      creator_of_work: ["Joe Factory"],
      publisher: ["Not Publisher"],
      place_of_publication: ["Not this place"],
      medium: ["Iron", "Wood"],
      date_uploaded: date_uploaded,
      dates_of_work: nil
    )}
    before do
      allow(work).to receive(:date_of_work).and_return([DateOfWork.new(start: "1916")])
    end

    it "replaces authors" do
      expect(citable_attributes.authors.length).to eq(1)
      expect(citable_attributes.authors).to include(CiteProc::Name.new(literal: "Science History Institute"))
    end
    it "replaces medium" do
      expect(citable_attributes.medium).to eq("photograph")
    end
    it "has no publisher" do
      expect(citable_attributes.publisher).to be_nil
    end
    it "has no publisher_place" do
      expect(citable_attributes.publisher_place).to be_nil
    end
    it "uses date_uploaded for date" do
      expect(citable_attributes.date).to eq(CiteProc::Date.new([date_uploaded.year]))
    end
  end

  describe "Special case oral history" do
    # based on https://digital.sciencehistory.org/concern/generic_works/gh93h041p
    # https://othmerlib.sciencehistory.org/record=b1043559
    let(:work) { FactoryGirl.build(:oral_history_work) }

    it "has oral-history-style title" do
      expect(citable_attributes.title).to eq("William John Bailey, interviewed by James J. Bohning at University of Maryland, College Park on June 3, 1986")
    end
    it "has no authors" do
      expect(citable_attributes.authors.length).to eq(0)
    end
    it "has no medium" do
     expect(citable_attributes.medium).to eq(nil)
    end
    it "replaces publisher" do
      expect(citable_attributes.publisher).to eq("Science History Institute")
    end
    it "replaces publisher place" do
      expect(citable_attributes.publisher_place).to eq ('Philadelphia')
    end
    it "supplies OH interview number as archive location" do
      expect(citable_attributes.archive_location).to eq ('Oral History Transcript 0012')
    end


  end # describe special case oral history
end
