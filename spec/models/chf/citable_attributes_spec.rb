require 'spec_helper'

#   "Hawes, R. C.", "Beckman Instruments, inc."]

describe CHF::CitableAttributes do
  let(:citable_attributes) { CHF::CitableAttributes.new(work)}

  describe "standard treatment" do
    let(:work) { FactoryGirl.build(:generic_work)}

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
    end

    describe "publisher" do
      describe "with inverted form with dates" do
        before do
          work.publisher = ["Sackett, Israel, 1809-1880", "Smith, John"]
        end
        it "sets first in direct form" do
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
        work.place_of_publication = ["Maryland--Baltimore", "Does not use"]
      end
      it "uses direct corporate name" do
        expect(citable_attributes.publisher_place).to eq("Baltimore, Maryland")
      end
    end

    describe "medium" do
      before do
        work.medium = ["Vellum", "Leather"]
      end
      it "joins" do
        expect(citable_attributes.medium).to eq("vellum, leather")
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
          expect(citable_attributes.archival_location).to be_nil
        end
      end
      describe "Archives" do
        before do
          work.division = "Archives"
          work.series_arrangement = ["Subseries B", "Series XIV"]
          work.physical_container = "b56|f47"
          allow(work).to receive("in_collections").and_return([FactoryGirl.build(:collection, title: ["Collection Name"])])
        end
        it "includes collection box and folder but not series" do
          expect(citable_attributes.archival_location).to eq("Collection Name, Box 56, Folder 47")
        end
      end
    end

    describe "dates" do
      before do
        allow(work).to receive(:date_of_work).and_return(date_of_work)
      end
      describe "one date year-only" do
        let(:date_of_work) { [DateOfWork.new(start: "1916")] }
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
            DateOfWork.new(start: "1916", finish: "1920"),
            DateOfWork.new(start: "1940", finish: "1960"),
            DateOfWork.new(start: "1910")
          ]
        end

        it ("gets the right CiteProc::Date range") do
          expect(citable_attributes.date).to eq(CiteProc::Date.new([[1910], [1960]]))
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
      date_uploaded: date_uploaded
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
      expect(citable_attributes.date).to eq(CiteProc::Date.new([date_uploaded.year, date_uploaded.month, date_uploaded.day]))
    end
  end
end
