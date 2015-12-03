# set up local config values, and overwrite any in sufia that we changed.
# WARNING: changes may necessitate data migration!!
Sufia.config do |config|

  # model configuration
  config.makers = {
    artist:       ::RDF::Vocab::MARCRelators.art,
    author:       ::RDF::Vocab::MARCRelators.aut,
    creator_of_work:      ::RDF::Vocab::DC11.creator,
    contributor:  ::RDF::Vocab::DC11.contributor,
    interviewee:  ::RDF::Vocab::MARCRelators.ive,
    interviewer:  ::RDF::Vocab::MARCRelators.ivr,
    manufacturer: ::RDF::Vocab::MARCRelators.mfr,
    photographer: ::RDF::Vocab::MARCRelators.pht,
    publisher:    ::RDF::Vocab::DC11.publisher,
  }

  config.places = {
    place_of_interview: ::RDF::Vocab::MARCRelators.evp,
    place_of_manufacture: ::RDF::Vocab::MARCRelators.mfp,
    place_of_publication: ::RDF::Vocab::MARCRelators.pup,
  }

  # form field configuration
  config.credit_names = [
    'Douglas Lockard',
    'Gregory Tobias',
    'Mark Backrath',
    'Penn School of Medicine',
    'Will Brown',
  ]

  config.credit_roles = {
    'photographer' => 'Photographed by',
  }

  config.cc_licenses = {
    'Public Domain Mark 1.0' => 'http://creativecommons.org/publicdomain/mark/1.0/',
    'All rights reserved' => 'All rights reserved'
  }

  config.divisions = [
    'Archives',
    'Center for Oral History',
    'Museum',
    'Othmer Library of Chemical History',
  ]

  config.file_creators = [
    'Brown, Will',
    'DiMeo, Michelle',
    'George Blood Audio LP',
    'Kativa, Hillary',
    'Lockard, Douglas',
    'Lu, Cathleen',
    'Newhouse, Sarah',
    'The University of Pennsylvania Libraries',
    'Tobias, Gregory',
    'Voelkel, James',
  ]

  config.external_ids_hash = {
    'object' => 'Object ID',
    'bib' => 'Sierra Bib. No.',
    'item' => 'Sierra Item No.',
    'accn' => 'Accession No.',
    'aspace' => 'ASpace Reference No.',
    'interview' => 'Oral History Interview No.',
  }

  config.genres = [
    'Advertisements',
    'Artifacts',
    'Business correspondence',
    'Chemistry sets',
    'Engravings',
    'Etchings',
    'Handbooks and manuals',
    'Manuscripts',
    'Minutes (Records)',
    'Oral histories',
    'Paintings',
    'Pamphlets',
    'Personal correspondence',
    'Photographs',
    'Plastics',
    'Portraits',
    'Prints',
    'Rare books',
    'Records (Documents)',
    'Scientific apparatus and instruments',
    'Slides',
  ]

  config.physical_container_fields = {
    'b'=>'box', 'f'=>'folder', 'v'=>'volume', 'p'=>'part'
  }

  config.resource_types = {
    "Image" => "Image",
    "Moving Image" => "Moving Image",
    "Physical Object" => "Physical Object",
    "Sound" => "Sound",
    "Text" => "Text"
  }

  config.resource_types_to_schema = {
    "Moving Image" => "http://purl.org/dc/dcmitype/MovingImage",
    "Image" => "http://purl.org/dc/dcmitype/StillImage",
    "Physical Object" => "http://purl.org/dc/dcmitype/PhysicalObject",
    "Sound" => "http://purl.org/dc/dcmitype/Sound",
    "Text" => "http://purl.org/dc/dcmitype/Text"
  }

end
