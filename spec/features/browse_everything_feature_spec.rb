require 'rails_helper'
RSpec.feature "BrowseEverything client for s3 files", js: true do
  let!(:user) { FactoryGirl.create(:depositor) }
  before do
    login_as(user, :scope => :user)
    set_up_fake_browser_and_client()
    Capybara.default_max_wait_time = 1000
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
    click_on "I Accept"
    click_on "Browse cloud files"
    sleep 2
    find(:xpath, '//select/option[normalize-space(text())="Scihist S3"]').select_option
    sleep 2
    find_all('input[type=checkbox]')[1].click
    find_all('input[type=checkbox]')[2].click
    click_on "Submit"
    stub_image_requests('sample_2.tiff')
    stub_image_requests('sample_3.tiff')
    expect {
      Capybara.using_wait_time 100 do
        click_on "Save"
      end
    }.to change(GenericWork, :count).by(1)
    file_set_labels = FileSet.all.map { |x|  x.label }
    expect(file_set_labels).to include('sample_2.tiff')
    expect(file_set_labels).to include('sample_3.tiff')
    newly_added_work = GenericWork.last
    expect(page).to have_current_path(curation_concerns_generic_work_path(newly_added_work.id))
    expect(page.source).to include('Download all 2 images')
  end
end

private

  def set_up_fake_browser_and_client()
    BrowseEverything.configure(
      'scihist_s3' => { app_key: 'S3AppKey', app_secret: 'S3AppSecret', bucket: 's3.bucket', response_type: :signed_url, :base=>"/"}
    )
    fake_files = ['sample_1.tiff', 'sample_2.tiff', 'sample_3.tiff', ].map { |x| fake_file(x)}
    fake_aws_s3_client = Aws::S3::Client.new(stub_responses: true)
    fake_aws_s3_client.stub_responses(:list_objects,
        Aws::S3::Types::ListObjectsOutput.new(
        is_truncated: false,   marker: '',
        next_marker: nil,      name: 's3.bucket',
        delimiter: '/',        max_keys: 1000,
        encoding_type: 'url',  contents: fake_files,
        common_prefixes: []
      )
    )
    allow_any_instance_of(BrowseEverything::Driver::ScihistS3).to receive(:client).and_return(fake_aws_s3_client)
  end

  def fake_file(title)
    Struct.new(:key, :size, :last_modified, :type, :id,
      :location, :name, :etag, :storage_class, :owner).new(
        "/spec/fixtures/#{title}",
        44121544,
        Time.now(),
        'image/tiff',
        'file_id_01234',
        '/spec/fixtures/#{title}',
        title,
        '"4e2ad532e659a65e8f106b350255a7ba"',
        'STANDARD',
        { display_name: 'mbklein' }
    )
  end

  def stub_image_requests (filename)
    link = BrowseEverything::Browser.new().providers['scihist_s3'].link_for("/spec/fixtures/#{filename}")[0]
    path_to_image = File.join([Rails.root, 'spec', 'fixtures', filename])
    body_file = File.open(path_to_image)
    stub_request(:head, link).to_return(status: 200, body: "", headers: {})
    stub_request(:get, link).to_return(body: body_file, status: 200)
  end