require 'rails_helper'
RSpec.describe Admin::FixityController, type: :controller do
    context "a guest user" do
      before { allow(controller.current_ability).to receive(:can?).and_return(false) }
      it "can't see the page" do
        get :index
        expect(response).to be_redirect
      end
    end
    context "authorized user, no fixity problems" do
      let!(:fixity_check_1) { FactoryGirl.create(:checksum_audit_log) }
      let!(:fixity_check_2) { FactoryGirl.create(:checksum_audit_log) }
      before do
        allow(controller.current_ability).to receive(:can?).and_return(true)
      end
      it "sees the dashboard; no failed checks reported." do
        get :index
        expect(response).to be_successful
        expect(controller.instance_variable_get(:@failed_check_count)).to eq 0
      end
    end
    context "a check has failed" do
      let!(:fixity_check_1) { FactoryGirl.create(:checksum_audit_log, :failed) }
      let!(:fixity_check_2) { FactoryGirl.create(:checksum_audit_log) }
      before do
        allow(controller.current_ability).to receive(:can?).and_return(true)
      end
      it "dashboard reports the problems" do
        get :index
        expect(response).to be_successful
        expect(controller.instance_variable_get(:@failed_check_count)).to eq 1
      end
    end
end