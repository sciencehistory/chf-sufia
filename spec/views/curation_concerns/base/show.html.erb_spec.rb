require 'rails_helper'

describe 'curation_concerns/base/show.html.erb' do
  let(:solr_document) {
    SolrDocument.new(
      id: '999',
      object_profile_ssm: ["{\"id\":\"999\"}"],
      has_model_ssim: ['GenericWork'],
      human_readable_type_tesim: ['Generic Work'],
      title_tesim: ['Super Mario'],
      physical_container_tesim: ['b2|f3|v4|p5|g234'],
      identifier_tesim: ['object-2004', 'bib-b123456789', 'object-2004-09.003'],
      creator_of_work_tesim: ['Chain Chomp'],
      contributor_tesim: ['Blooper'],
      artist_tesim: ['Boo'],
      author_tesim: ['Cheep Cheep'],
      addressee_tesim: ['Koopa'],
      interviewee_tesim: ['Birdo'],
      interviewer_tesim: ['Thwomp'],
      manufacturer_tesim: ['Piranha Plant'],
      photographer_tesim: ['Sparky'],
      publisher_tesim: ['Hammer Bro'],
      #date_of_work: ['February 9, 1990'],
      #date_created
      place_of_interview_tesim: ['Underwater'],
      place_of_manufacture_tesim: ['Cloudland'],
      place_of_publication_tesim: ['Pyramid'],
      place_of_creation_tesim: ['Castle'],
      resource_type_tesim: ['Mushroom'],
      genre_string_tesim: ['Platformer'],
      medium_tesim: ['Digital'],
      extent_tesim: ['Infinity'],
      language_tesim: ['Mute'],
      description_tesim: ['Fun'],
      #inscription
      subject_tesim: ['gold coins'],
      division_tesim: ['Nintendo'],
      series_arrangement_tesim: ['Ongoing'],
      related_url_tesim: ['example.com'],
      rights_tesim: ['http://rightsstatements.org/vocab/InC/1.0/'],
      rights_holder_tesim: ['Luigi'],
      credit_line_tesim: ['Courtesy of CHF Collections'],
      #additional_credit:
      file_creator_tesim: ['Miyamoto'],
      admin_note_tesim: ['Mario Kart'],
    )
  }

  let(:ability) { nil }
  let(:presenter) do
    CurationConcerns::GenericWorkShowPresenter.new(solr_document, ability)
  end

  before do
    stub_template 'curation_concerns/base/_relationships.html.erb' => ''
    stub_template 'curation_concerns/base/_show_actions.html.erb' => ''
    stub_template 'curation_concerns/base/_representative_media.html.erb' => ''
    stub_template 'curation_concerns/base/_social_media.html.erb' => ''
    stub_template 'curation_concerns/base/_citations.html.erb' => ''
    stub_template 'curation_concerns/base/_items.html.erb' => ''
    assign(:presenter, presenter)
    render
  end

  describe 'local fields display' do
    xit 'parses physical container' do
      expect(rendered).to match /Box 2, Folder 3, Volume 4, Part 5, Page 234/
    end
    it 'parses external ID' do
      expect(rendered).to match /Object ID: 2004/
      expect(rendered).to match /Sierra Bib. No.: b123456789/
      expect(rendered).to match /Object ID: 2004-09.003/
    end
    it 'displays all fields' do
      expect(rendered).to match /Chain Chomp/
      expect(rendered).to match /Blooper/
      expect(rendered).to match /Boo/
      expect(rendered).to match /Cheep Cheep/
      expect(rendered).to match /Koopa/
      expect(rendered).to match /Birdo/
      expect(rendered).to match /Thwomp/
      expect(rendered).to match /Piranha Plant/
      expect(rendered).to match /Sparky/
      expect(rendered).to match /Hammer Bro/
      #date_of_work: ['February 9, 1990'],
      #date_created
      expect(rendered).to match /Underwater/
      expect(rendered).to match /Cloudland/
      expect(rendered).to match /Pyramid/
      expect(rendered).to match /Castle/
      expect(rendered).to match /Mushroom/
      expect(rendered).to match /Platformer/
      expect(rendered).to match /Digital/
      expect(rendered).to match /Infinity/
      expect(rendered).to match /Mute/
      expect(rendered).to match /Fun/
      #inscription
      expect(rendered).to match /gold coins/
      expect(rendered).to match /Nintendo/
      expect(rendered).to match /Ongoing/
      expect(rendered).to match /example.com/
      expect(rendered).to match /rightsstatements\.org/
      expect(rendered).to match /Luigi/
      expect(rendered).to match /Courtesy of CHF Collections/
      #additional_credit:
      expect(rendered).to match /Miyamoto/
      expect(rendered).to match /Mario Kart/
    end
  end

end
