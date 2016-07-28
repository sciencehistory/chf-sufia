require 'rails_helper'

describe Sufia::BatchUploadsController do
  it 'uses local form' do
    expect(described_class.form_class).to eq BatchUploadForm
  end
end

