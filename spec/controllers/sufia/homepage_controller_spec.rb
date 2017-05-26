require 'rails_helper'

describe Sufia::HomepageController do
  it 'uses local layout override' do
    expect(described_class._layout).to eq 'sufia'
  end
end
