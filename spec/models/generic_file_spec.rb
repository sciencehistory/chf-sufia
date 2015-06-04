require 'rails_helper'

RSpec.describe GenericFile, focus: true do
  it { is_expected.to respond_to(:interviewee) }

  describe 'marc relator creator / contributor fields' do
    let :generic_file do
      described_class.create(title: ['title1']) do |gf|
        gf.apply_depositor_metadata('dpt')
        gf.interviewee = ['Beckett, Samuel']
      end
    end
    it 'has a single interviewee' do
      expect(generic_file.interviewee.count).to eq 1
      expect(generic_file.interviewee).to include 'Beckett, Samuel'
    end
  end
end
