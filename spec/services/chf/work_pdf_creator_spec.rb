require 'rails_helper'

# This is gonna be CRAZY slow to run, mainly becuase it's so slow to create
# the objects in fedora, not cause PDF generation is actually that slow. :(
RSpec.describe CHF::WorkPdfCreator do
  before do
    allow(Hydra::Works::CharacterizationService).to receive(:run).and_return(nil)
  end

  after do
    FileUtils.rm_f(pdf_output_path)
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

  let(:pdf_output_path) { "tmp/pdf_test.pdf" }

  it "smoke tests" do
    creator = CHF::WorkPdfCreator.new(work.id)
    creator.write_pdf_to_path(pdf_output_path, callback: callback_spy)

    # open it and make sure it's a PDF with num pages we expect
    reader = PDF::Reader.new(pdf_output_path)

    expect(reader.page_count).to eq 3
    expect(callback_spy).to have_received(:call).with(progress_total: 3, progress_i: 1)
    expect(callback_spy).to have_received(:call).with(progress_total: 3, progress_i: 3)

    # we are adding metadata, but PDF::Reader can't find it for some reason.
    # https://github.com/yob/pdf-reader/issues/274
    #expect(reader.metadata).to be_present
  end
end
