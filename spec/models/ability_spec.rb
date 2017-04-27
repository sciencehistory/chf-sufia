require 'rails_helper'
require 'cancan/matchers'

RSpec.describe Ability do
  let(:staff) { FactoryGirl.create(:user) }
  let(:admin) { FactoryGirl.create(:user, :admin) }
  let(:staff_work) { FactoryGirl.create(:work, user: staff) }
  let(:admin_work) { FactoryGirl.create(:work, user: admin) }

  describe "an unprivileged user" do
    it "is not an admin" do
      expect(staff.admin?).not_to eq true
    end

    it "cannot manage Roles" do
      expect(staff).not_to be_able_to(:read, Role)
      expect(staff).not_to be_able_to(:add_user, Role)
      expect(staff).not_to be_able_to(:remove_user, Role)
      expect(staff).not_to be_able_to(:destroy, Role)
      expect(staff).not_to be_able_to(:create, Role)
      expect(staff).not_to be_able_to(:edit, Role)
    end
  end

  describe "an admin user" do

    it "is an admin" do
      expect(admin.admin?).to eq true
    end

    it "can manage users' Role membership" do
      expect(admin).to be_able_to(:read, Role)
      expect(admin).to be_able_to(:add_user, Role)
      expect(admin).to be_able_to(:remove_user, Role)
      expect(admin).not_to be_able_to(:destroy, Role)
      expect(admin).not_to be_able_to(:create, Role)
      expect(admin).not_to be_able_to(:edit, Role)
    end

    it "can modify another user's work" do
      expect(admin).to be_able_to(:update, staff_work)
    end
  end
end
