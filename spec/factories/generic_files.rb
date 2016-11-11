FactoryGirl.define do
  factory :generic_file do
    before(:create) do |gf|
      gf.apply_depositor_metadata FactoryGirl.create(:depositor)
    end

    trait :with_additional_credit do
      additional_credit_attributes [{role: "photographer", name: "Puffins"}]
    end

    trait :with_inscription do
      inscription_attributes [{location: "inscriptionlocation", text: "inscriptiontext"}]
    end

    trait :with_date_of_work do
      date_of_work_attributes [{start: "1920", start_qualifier: "circa", finish: "1929", finish_qualifier: "before", note: "The twenties"}]
    end

    trait :with_complete_metadata do
      additional_credit_attributes [{role: "photographer", name: "Puffins"}]
      date_of_work_attributes [{start: "1920", start_qualifier: "circa", finish: "1929", finish_qualifier: "before", note: "The twenties"}]
      inscription_attributes [{location: "inscriptionlocation", text: "inscriptiontext"}]
      title         ['titletitle']
      label         'labellabel'
      filename      ['filename.filename']
      based_near    ['based_nearbased_near']
      language      ['languagelanguage']
      creator       ['creatorcreator']
      contributor   ['contributorcontributor']
      publisher     ['publisherpublisher']
      subject       ['subjectsubject']
      resource_type ['resource_typeresource_type']
      description   ['descriptiondescription']
      format_label  ['format_labelformat_label']
      related_url   ['http://example.org/TheRelatedURLLink/']
      date_created  ['date_createddate_created']
      bibliographic_citation ['bibliographic_citationbibliographic_citation']
      artist ['artistartist']
      author ['authorauthor']
      addressee ['addresseeaddressee']
      creator_of_work ['creator_of_workcreator_of_work']
      engraver ['engraverengraver']
      interviewee ['intervieweeinterviewee']
      interviewer ['interviewerinterviewer']
      manufacturer ['manufacturermanufacturer']
      photographer ['photographerphotographer']
      printer_of_plates ['printerprinter']
      place_of_interview ['place_of_interviewplace_of_interview']
      place_of_manufacture ['place_of_manufactureplace_of_manufacture']
      place_of_publication ['place_of_publicationplace_of_publication']
      place_of_creation ['place_of_creationplace_of_creation']
      admin_note ['admin_noteadmin_note']
      credit_line ['Courtesy of CHF']
      division 'divisiondivision'
      file_creator 'file_creatorfile_creator'
      genre_string ['genre_stringgenre_string']
      extent ['extentextent']
      medium ['mediummedium']
      physical_container 'physical_containerphysical_container'
      rights_holder 'rights_holderrights_holder'
      series_arrangement ['seriesseries']
      rights ['rightslicense']
      identifier ['external_id']
      ##visibility
    end

    trait :with_system_metadata do
      arkivo_checksum 'checksumchecksum'
      relative_path 'relpathrelpath'
      import_url 'importurlimporturl'
      date_uploaded DateTime.new(2016, 6, 21, 9, 8)
      date_modified DateTime.new(2016, 6, 21, 9, 8)
      source ['sourcesource']
    end
  end
end
