require 'rails_helper'

describe Sufia::BatchUploadsController do
  it 'uses local form' do
    expect(described_class.work_form_service.form_class).to eq BatchUploadForm
  end
end

