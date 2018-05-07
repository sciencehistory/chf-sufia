require 'rails_helper'

# This is gonna be CRAZY slow to run, mainly becuase it's so slow to create
# the objects in fedora, not cause PDF generation is actually that slow. :(
RSpec.describe CHF::WorkZipCreator do
  before do
    allow(Hydra::Works::CharacterizationService).to receive(:run).and_return(nil)
  end

  after do
    # TODO remove tempfile
    #FileUtils.rm_f(zip_output_path)
  end

  let(:callback_spy) { spy("callback") }

  let!(:work) do
    work = FactoryGirl.create(:work, :real_public_image, num_images: 2 )
    child_work = FactoryGirl.create(:work, :real_public_image)
    work.members << child_work
    work.ordered_members << child_work
    work.save!
    child_work.save!

    work
  end


  it "smoke tests" do
    creator = CHF::WorkZipCreator.new(work.id)
    zip_file = creator.create_zip(callback: callback_spy)

    found_entries = []
    Zip::File.open(zip_file.path) do |zip_file|
      expect(zip_file.comment).to include "Science History Institute"

      zip_file.each do |entry|
        found_entries << { name: entry.name, size: entry.size}
      end
    end

    expect(callback_spy).to have_received(:call).with(progress_total: 3, progress_i: 1)
    expect(callback_spy).to have_received(:call).with(progress_total: 3, progress_i: 3)
    expect(found_entries.size).to eq 4
    expect(found_entries.find { |e| e[:name] == "about.txt"}).not_to be nil

    zip_file.close
    zip_file.unlink
  end
end
