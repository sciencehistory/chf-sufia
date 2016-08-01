require 'rails_helper'

RSpec.describe CreateDerivativesJob do
  before do
    @generic_file = GenericFile.create { |gf| gf.apply_depositor_metadata('user@example.com') }
  end

  subject { described_class.new(@generic_file.id) }

  describe 'preview jpeg generation' do
    before do
      @generic_file.add_file(File.open("#{::Rails.root}/spec/fixtures/#{file_name}"), path: 'content', original_name: file_name, mime_type: mime_type)
      allow_any_instance_of(GenericFile).to receive(:mime_type).and_return(mime_type)
      @generic_file.save!
    end
    context 'with an image (png) file' do
      let(:mime_type) { 'image/png' }
      let(:file_name) { 'image.png' }

      it 'lacks an preview derivative' do
        expect(@generic_file.preview).not_to have_content
      end

      it 'generates an preview derivative on job run' do
        subject.run
        @generic_file.reload
        expect(@generic_file.preview).to have_content
        expect(@generic_file.preview.mime_type).to eq('image/jpeg')
      end
    end

  end
end

