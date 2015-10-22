require 'rails_helper'

RSpec.describe GenericFilePresenter do
  subject { GenericFilePresenter.new(file) }

  let(:file) { GenericFile.new }

  describe "#inscription_attributes=" do
    it "should delegate down to the object" do
      allow(file).to receive(:inscription_attributes=)

      subject.inscription_attributes = {}

      expect(file).to have_received(:inscription_attributes=).with({})
    end
    it "should respond to it" do
      expect(subject).to respond_to :inscription_attributes=
    end
  end
end
