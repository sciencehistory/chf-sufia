require 'rails_helper'

RSpec.describe CHF::Utils::Admin do
  let(:user1) { FactoryGirl.create(:user) }
  let!(:admin_role) do
    Role.find_or_create_by!(name: 'admin')
  end

  before do
    CHF::Utils::Admin.grant(user1.email)
  end

  describe '.grant' do
    it 'makes the user an admin' do
      expect(user1.reload.roles).to include admin_role
    end

    it "raises exception if the user doesn't exist" do
      expect { CHF::Utils::Admin.grant("nobody@example.com") }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe '.revoke' do
    it "revokes the user's admin role" do
      expect(user1.roles).to include admin_role
      CHF::Utils::Admin.revoke(user1.email)
      expect(user1.roles).not_to include admin_role
    end
  end
end
