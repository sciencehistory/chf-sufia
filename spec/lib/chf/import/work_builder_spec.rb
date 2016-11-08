require 'rails_helper'

describe Chf::Import::WorkBuilder do
  let(:builder) { described_class.new }

  let(:json) do
    { "id": "th83kz34n",
      "depositor": "aheadley@chemheritage.org",
      "title": [ "cat" ],
      # code requires this and it will be in all our exports
      "rights": [],
      # app really makes it impossible to have a gf with no perms
      "permissions": [],
      "date_of_work": [
        {
          "id": "h989r331m",
          "start": "2000",
          "finish": "2016",
          "start_qualifier": "after",
          "finish_qualifier": "before",
          "note": "not sure exactly when"
        }
      ],
      "inscription": [
        {
          "id": "b5644r666",
          "location": "inside",
          "text": "awesomeness"
        }
      ],
      "additional_credit": [
        {
          "id": "8p58pd01g",
          "role": "photographer",
          "name": "Will Brown",
          "label": "Photographed by Will Brown"
        }
      ],
      "artist": [ "Francis William Aston"],
      "author": [ "Amedeo Avogadro"],
      "addressee": [ "Emil Abderhalden"],
      "creator_of_work": [ "Frederick Abel"],
      "contributor": [ "Richard Abegg"],
      "interviewee": [ "Friedrich Accum"],
      "interviewer": [ "Homer Burton Adkins"],
      "manufacturer": [ "Peter Agre"],
      "photographer": [ "Georgius Agricola"],
      "publisher": [ "Arthur Aikin"],
      "place_of_interview": [ "Adrien Albert"],
      "place_of_manufacture": [ "John Albery"],
      "place_of_publication": [ "Kurt Alder"],
      "place_of_creation": [ "Sidney Altman"],
      "admin_note": [ "Christian B. Anfinsen"],
      "credit_line": [ "Angelo Angeli"],
      "genre_string": [ "Johan August Arfwedson"],
      "extent": [ "Anton Eduard van Arkel"],
      "medium": [ "Svante Arrhenius"],
      "resource_type": [ "Stephen Moulton Babcock"],
      "rights": [ "Werner Emmanuel Bachmann"],
      "series_arrangement": [ "Adolf von Baeyer"],
      "division": "Octavio Augusto Ceva Antunes",
      "file_creator": "Anthony Joseph Arduengo, III",
      "physical_container": "b4|f78|v2|p27|g3",
      "rights_holder": "Leo Baekeland"
    }
  end

  #let(:permission_builder) { instance_double(Sufia::Import::PermissionBuilder) }
  let(:inscription_builder) { instance_double(Chf::Import::InscriptionBuilder) }
  let(:date_of_work_builder) { instance_double(Chf::Import::DateOfWorkBuilder) }
  let(:credit_builder) { instance_double(Chf::Import::CreditBuilder) }
  before do
    #allow(Sufia::Import::PermissionBuilder).to receive(:new).and_return(permission_builder)
    allow(Chf::Import::InscriptionBuilder).to receive(:new).and_return(inscription_builder)
    allow(Chf::Import::DateOfWorkBuilder).to receive(:new).and_return(date_of_work_builder)
    allow(Chf::Import::CreditBuilder).to receive(:new).and_return(credit_builder)
  end

  it "creates a Work with local fields and nested objects" do
    #expect(permission_builder).to receive(:build).with(an_instance_of(Sufia.primary_work_type), gf_metadata[:permissions])
    expect(inscription_builder).to receive(:build).with(an_instance_of(Sufia.primary_work_type), json[:inscription])
    expect(date_of_work_builder).to receive(:build).with(an_instance_of(Sufia.primary_work_type), json[:date_of_work])
    expect(credit_builder).to receive(:build).with(an_instance_of(Sufia.primary_work_type), json[:additional_credit])
    work = builder.build(json)
    expect(work.artist).to include "Francis William Aston"
    expect(work.author).to include "Amedeo Avogadro"
    expect(work.addressee).to include "Emil Abderhalden"
    expect(work.creator_of_work).to include "Frederick Abel"
    expect(work.contributor).to include "Richard Abegg"
    expect(work.interviewee).to include "Friedrich Accum"
    expect(work.interviewer).to include "Homer Burton Adkins"
    expect(work.manufacturer).to include "Peter Agre"
    expect(work.photographer).to include "Georgius Agricola"
    expect(work.publisher).to include "Arthur Aikin"
    expect(work.place_of_interview).to include "Adrien Albert"
    expect(work.place_of_manufacture).to include "John Albery"
    expect(work.place_of_publication).to include "Kurt Alder"
    expect(work.place_of_creation).to include "Sidney Altman"
    expect(work.admin_note).to include "Christian B. Anfinsen"
    expect(work.credit_line).to include "Angelo Angeli"
    expect(work.genre_string).to include "Johan August Arfwedson"
    expect(work.extent).to include "Anton Eduard van Arkel"
    expect(work.medium).to include "Svante Arrhenius"
    expect(work.resource_type).to include "Stephen Moulton Babcock"
    expect(work.rights).to include "Werner Emmanuel Bachmann"
    expect(work.series_arrangement).to include "Adolf von Baeyer"
    expect(work.division).to eq "Octavio Augusto Ceva Antunes"
    expect(work.file_creator).to eq "Anthony Joseph Arduengo, III"
    expect(work.physical_container).to eq "b4|f78|v2|p27|g3"
    expect(work.rights_holder).to eq "Leo Baekeland"
  end

end
