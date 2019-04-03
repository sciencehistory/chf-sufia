require 'rails_helper'
RSpec.describe CHF::AudioDerivativeMaker do
  ffmpeg_is_available = true
  before do
    allow(CHF::CreateDerivativesOnS3Service).to receive(:s3_bucket!).and_return(nil)
    unless ffmpeg_is_available
      # don't actually run the command if ffmpeg isn't installed.
      allow(adm).to receive(:run_command).and_return(true)
    end
    allow(adm).to receive(:s3_obj_for_this_file).and_return(nil)
    allow(adm).to receive(:we_need_this_derivative?).and_return(true)
    allow(adm).to receive(:download_file_from_fedora).and_return(Rails.root.join('spec/fixtures/sample.mp3'))
    allow(adm).to receive(:upload_file_to_s3).and_return(true)
    allow(adm).to receive(:report_success).and_return(nil)
  end

  let(:adm) do
    file_info = {
      :file_id=>"asd", :file_checksum=>"asd",
      :file_set=>FactoryGirl.create(:file_set),
      :file_set_content_type=>"audio/mpeg",
    }
    CHF::AudioDerivativeMaker.new(file_info, false)
  end

  after do
    FileUtils.rm adm.instance_variable_get(:@working_dir), :force => true
  end

  it "checks the right arguments are sent to ffmpeg" do
    adm.create_and_upload_derivatives()
    webm_settings = CHF::AudioDerivativeMaker::AUDIO_DERIVATIVE_FORMATS[:standard_webm]
    webm_args = adm.send(:convert_command_args,  webm_settings, '/tmp/webm_file.webm')
    mp3_settings = CHF::AudioDerivativeMaker::AUDIO_DERIVATIVE_FORMATS[:standard_mp3]
    mp3_args = adm.send(:convert_command_args,  mp3_settings, '/tmp/mp3_file.mp3')
    failed_mp3  = /ffmpeg -i [^ ]*sample.mp3 -ac 1 -b:a 64k [^ ]*mp3_file.mp3/.
      match(mp3_args.join(" ")).nil?
    failed_webm = /ffmpeg -i [^ ]*sample.mp3 -ac 1 -codec:a libopus -b:a 64k [^ ]*webm_file.webm/.
      match(webm_args.join(" ")).nil?
    expect(failed_mp3 && failed_webm).to be false
  end

  if ffmpeg_is_available
    it "creates derivatives" do
      adm.create_and_upload_derivatives()
      derivs = Dir.entries(adm.instance_variable_get(:@working_dir))
      expect(derivs.sort).to eq([".", "..", "standard_mp3.mp3", "standard_webm.webm"])
    end
  end
end
