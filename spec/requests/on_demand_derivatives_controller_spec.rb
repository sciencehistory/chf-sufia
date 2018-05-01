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

      last = OnDemandDerivative.last
      expect(last).to be_present
      expect(last.work_id).to eq work.id
    end
  end

  describe "finished processing" do
    let!(:record) { OnDemandDerivative.find_or_create_record(work.id, "pdf").tap do |record|
      record.update(status: "success")
    end }

    it "returns json" do
      expect(CreateWorkPdfJob).not_to receive(:perform_later)

      get on_demand_pdf_path(work.id)

      expect(response.content_type).to eq("application/json")
      expect(response).to have_http_status(200)

      json = JSON.parse(response.body)

      expect(json["id"]).to eq record.id
      expect(json["status"]).to eq "success"
      expect(json["url"]).to be_kind_of String
    end
  end

end
