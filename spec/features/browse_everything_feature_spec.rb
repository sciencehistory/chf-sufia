require 'rails_helper'
file_names = ['sample_1.tiff', 'sample_2.tiff', 'sample_3.tiff']
used_file_names = file_names[1..2]

RSpec.feature "BrowseEverything client for s3 files", js: true do
  let!(:user) { FactoryGirl.create(:depositor) }
  before do
    login_as(user, :scope => :user)
    set_up_fake_browser_and_client(file_names)
    # no fits on travis
    allow_any_instance_of(CharacterizeJob).to receive(:perform).and_return(nil)
  end
  scenario "Attaches two files to a new work" do
    visit new_curation_concerns_generic_work_path
    fill_in("generic_work[title]", with: title)
    within(".form-group.generic_work_identifier") do
      within first(".field-wrapper") do
        select "Sierra Bib. No."
        fill_in "generic_work[bib_external_id][]", with: "12345"
      end
    end
    find('#generic_work_visibility_open').click
    click_on "Files"
    click_on "Browse cloud files"
    sleep 2
    find(:xpath, '//select/option[normalize-space(text())="Scihist S3"]').select_option
    sleep 2
    find_all('input[type=checkbox]')[1].click
    find_all('input[type=checkbox]')[2].click
    click_on "Submit"
    used_file_names.each {|f| stub_image_requests(f)}
    expect {
      click_on "Save"
    }.to change(GenericWork, :count).by(1)
    file_set_labels = FileSet.all.map { |x|  x.label }
    used_file_names.each{|x| expect(file_set_labels).to include(x)}
    expected_path = curation_concerns_generic_work_path(GenericWork.last.id)
    expect(page).to have_current_path(expected_path)
    expect(page.source).to include('Download all 2 images')
  end
end

def set_up_fake_browser_and_client(file_names)
  BrowseEverything.configure(
    'scihist_s3' => { bucket: 's3.bucket',
      response_type: :signed_url, :base=>"/" }
    )
  fake_aws_s3_client = Aws::S3::Client.new(stub_responses: true)
  fake_aws_s3_client.stub_responses(:list_objects,
      Aws::S3::Types::ListObjectsOutput.new(
      is_truncated: false,   marker: '',
      next_marker: nil,      name: 's3.bucket',
      delimiter: '/',        max_keys: 1000,
      encoding_type: 'url',
      contents: file_names.map{|x| fake_file(x)},
      common_prefixes: []
    )
  )
  allow_any_instance_of(BrowseEverything::Driver::ScihistS3).to receive(:client).and_return(fake_aws_s3_client)
end

def fake_file(title)
  path = "/spec/fixtures/#{title}"
  Struct.new(
    :key, :size, :last_modified, :type,
    :id, :location, :name).new(
    path, 44121544, Time.now(), 'image/tiff',
    'file_id_01234', path, title
  )
end

def stub_image_requests(filename)
  provider = BrowseEverything::Browser.new().providers['scihist_s3']
  link = provider.link_for("/spec/fixtures/#{filename}")[0]
  path_to_image = File.join([Rails.root, 'spec', 'fixtures', filename])
  body_file = File.open(path_to_image)
  stub_request(:head, link).to_return(status: 200, body: "", headers: {})
  stub_request(:get, link).to_return(body: body_file, status: 200)
end