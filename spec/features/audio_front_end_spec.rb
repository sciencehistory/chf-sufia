require 'rails_helper'
RSpec.feature "Audio front end", js: true do
  let(:user) { FactoryGirl.create(:depositor) }
  let(:ability) { Ability.new(nil) }
  let(:mock_files) {
    (1..3).to_a.map do |i|
      mock_model('MockFile', mime_type: 'audio/mpeg',
        duration:     ["0:29:5:31"], file_size: ["34900824"],
        channels:     ["2"], sample_rate: ["48000"],
        format_label: ["MPEG 1/2 Audio Layer 3"],
        file_name:    ["mark_h_0030_1-#{i}.mp3"],
        file_title:   ["mark_h_0030_1-#{i}.mp3"],
        id: 'file_id',
        checksum: OpenStruct.new(value: '0a1b2c3'),
        height: [], width: [], page_count: [],
        original_checksum: [], digest: [],
      )
    end
  }
  let(:file_sets) {
    (1..3).to_a.map do |i|
      FactoryGirl.create(:file_set, :public,
        label: "mark_h_0030_1-#{i}.mp3", title: ["Track #{i}"],
      )
    end
  }
  let(:work) {
    FactoryGirl.create(:work).tap do |work|
      work.ordered_members, work.members = file_sets, file_sets
      work.save!
    end
  }

  before do
    (0..2).to_a.map do |i|
      allow(file_sets[i]).to receive(:original_file).and_return(mock_files[i])
      allow(file_sets[i]).to receive(:files).and_return([mock_files[i]])
    end
    allow(CHF::AudioDerivativeMaker).to receive(:s3_url) do |args|
      suffixes = {standard_mp3: 'mp3', standard_webm: 'webm'}
      suffix = suffixes[args[:type_key]]
      "https://s3.amazonaws.com/#{args[:file_set_id]}_checksum#{args[:file_checksum]}/#{args[:type_key]}.#{suffix}"
    end
  end

  scenario "Non-staff user can see the playlist but not the regular item listings" do
    visit curation_concerns_generic_work_path(work)

    expect(page.find_all('.show-page-audio-wrapper').count ).to eq 0

    within(".show-page-audio-playlist-wrapper") do
      expect(page).to have_css(".current-track-label", :text => "Track 1")
      audio_element = page.find('.show-page-audio-playlist-wrapper audio')
      urls_playing = audio_element.find_all('source').map { |x| x['src'] }
      expect(urls_playing[0]).to match(/s3.amazonaws.com\/.*_checksum0a1b2c3\/standard_mp3.mp3/)
      expect(urls_playing[1]).to match(/s3.amazonaws.com\/.*_checksum0a1b2c3\/standard_webm.webm/)

      track_listings = page.find_all('.track-listing')
      expect(track_listings.map {|x| x['data-title'] }).to contain_exactly("Track 1", "Track 2", "Track 3")
      expect(track_listings.map {|x| x['data-member-id'] }).to eq file_sets.map {|x| x.id}

      download_links = page.find_all('.track-listings .dropdown-menu li a', :visible =>all).map { |x| x['href']}
      expect(download_links.count).to eq 6
      download_links.select{ |x| x.include? 'mp3'}.each{ |href|
        expect(href).to match(/s3.amazonaws.com\/.*_checksum0a1b2c3\/standard_mp3.mp3/)
      }
      expect(download_links.select{ |x| x.include? 'downloads'}.count).to eq 3
    end
  end


  scenario "Staff user can see the playlist and the regular item listings" do
    login_as(user, :scope => :user)
    visit curation_concerns_generic_work_path(work)

    # Basic check for the playlist, already tested above.
    within(".show-page-audio-playlist-wrapper") do
      expect(page).to have_css(".current-track-label", :text => "Track 1")
      track_listings = page.find_all('.track-listing')
      expect(track_listings.map {|x| x['data-title'] }).to contain_exactly("Track 1", "Track 2", "Track 3")
      expect(track_listings.map {|x| x['data-member-id'] }).to eq file_sets.map {|x| x.id}
    end

    # Now the .show-page-audio-wrapper blocks
    expect(page.find_all('.show-page-audio-wrapper').count ).to eq 3
    first_wrapper_div = find_all('.show-page-audio-wrapper')[0]
    expect(first_wrapper_div.find_all('h2')[0].text).to eq "Track 1 (mark_h_0030_1-1.mp3)"

    first_audio_item_sources = first_wrapper_div.
      find('audio').find_all('source').
      map {|x| x['src']}

    expect(first_audio_item_sources[0]).to match /s3.amazonaws.com\/.*_checksum0a1b2c3\/standard_mp3.mp3/
    expect(first_audio_item_sources[1]).to match /s3.amazonaws.com\/.*_checksum0a1b2c3\/standard_webm.webm/

    mp3_download, original_download, admin_link = first_wrapper_div.
      find_all('ul li a', :visible =>all).
      map {|x| x['href']}
    expect(mp3_download).to match "download_redirect\/#{file_sets[0].id}\/standard_mp3.filename_base=test_title_.*&no_content_disposition=false"
    expect(original_download).to match "downloads/#{file_sets[0].id}"
    expect(admin_link).to match "concern\/parent\/#{work.id}\/file_sets\/#{file_sets[0].id}"
  end


end
