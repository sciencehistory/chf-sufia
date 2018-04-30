require 'rails_helper'

RSpec.describe OnDemandDerivativesController, type: :request do
  let(:work) { FactoryGirl.create(:public_work) }

  describe "initial request" do
    it "creates record and returns json" do
      expect(CreateWorkPdfJob).to receive(:perform_later).once

      get on_demand_pdf_path(work.id)

      expect(response.content_type).to eq("application/json")
      expect(response).to have_http_status(200)

      json = JSON.parse(response.body)

      expect(json["work_id"]).to eq work.id
      expect(json["status"]).to eq "in_progress"
      expect(json["url"]).to be_kind_of String

      last = OnDemandDerivative.last
      expect(last).to be_present
      expect(last.work_id).to eq work.id
    end
  end

end
