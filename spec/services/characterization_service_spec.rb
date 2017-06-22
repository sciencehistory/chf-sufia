require 'rails_helper'
require 'support/file_set_helper'

RSpec.describe Hydra::Works::CharacterizationService do
  describe 'assigned properties.' do
    # Stub Hydra::FileCharacterization.characterize
    let(:characterization) { class_double("Hydra::FileCharacterization").as_stubbed_const }
    let(:file)             { Hydra::PCDM::File.new }

    before do
      allow(file).to receive(:content).and_return("mocked content")
      allow(characterization).to receive(:characterize).and_return(fits_response)
      described_class.run(file)
    end

    context 'using image metadata' do
      let(:fits_filename) { 'size_conflict.tiff.fits.xml' }
      let(:fits_response) { IO.read(File.join(Rails.root, "spec/fixtures", fits_filename)) }

      it 'assigns expected values to image properties.' do
        expect(file.width).to eq(["2226"])
        expect(file.height).to eq(["1650"])
      end
    end
  end
end
