require 'rails_helper'

RSpec.describe DashboardController, type: :controller do
  routes { Sufia::Engine.routes }
  context "with an authenticated user" do
    let(:user) { FactoryGirl.create(:depositor) }

    before do
      sign_in user
    end

    # TODO: test different statuses.
    context 'with transfers' do
      let(:another_user) { FactoryGirl.create(:user) }
      context 'when incoming' do
        let!(:incoming_file) do
          GenericFile.new.tap do |f|
            f.apply_depositor_metadata(another_user.user_key)
            f.save!
          end
        end

        before do
          pdr = ProxyDepositRequest.new(generic_file_id: incoming_file.id, sending_user: another_user,
            receiving_user: user, status: 'pending')
          pdr.save
          approved_file = GenericFile.new
          approved_file.apply_depositor_metadata another_user
          approved_file.save
          pdr = ProxyDepositRequest.new(generic_file_id: approved_file.id, sending_user: another_user,
            receiving_user: user, status: 'accepted')
          pdr.save
        end

        it 'assigns an instance variable' do
          get :index
          expect(response).to be_success
          expect(assigns[:incoming].count).to eq 1
          expect(assigns[:incoming].first).to be_kind_of ProxyDepositRequest
          expect(assigns[:incoming].first.generic_file_id).to eq(incoming_file.id)
        end
      end
    end

  end
end
