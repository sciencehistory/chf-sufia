require 'rails_helper'

describe Chf::Import::GenericFileTranslator do
  let(:translator) { described_class.new( {} ) }
  it 'uses local work builder' do
    expect(translator.instance_variable_get(:@work_builder).class).to eq Chf::Import::WorkBuilder
  end
end
