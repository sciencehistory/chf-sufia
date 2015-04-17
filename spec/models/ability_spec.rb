require 'rails_helper'
require 'cancan/matchers'

RSpec.describe Ability do

  describe "an unprivileged user" do
    let(:user) { FactoryGirl.create(:user) }

    it "is not an admin" do
      expect(user.admin?).not_to eq true
    end

    subject { user }
    it { is_expected.not_to be_able_to(:read, Role) }
    it { is_expected.not_to be_able_to(:add_user, Role) }
    it { is_expected.not_to be_able_to(:remove_user, Role) }
    it { is_expected.not_to be_able_to(:destroy, Role) }
    it { is_expected.not_to be_able_to(:edit, Role) }
    it { is_expected.not_to be_able_to(:create, Role) }
  end

  describe "an admin user" do
    before do
      @admin_role = Role.create name: "admin"
      @admin = FactoryGirl.create(:admin)
      @admin_role.users << @admin
      @admin_role.save
    end

    it "is an admin" do
      expect(@admin.admin?).to eq true
    end

    subject { @admin }
    it { is_expected.to be_able_to(:read, Role) }
    it { is_expected.to be_able_to(:add_user, Role) }
    it { is_expected.to be_able_to(:remove_user, Role) }
    it { is_expected.not_to be_able_to(:destroy, Role) }
    it { is_expected.not_to be_able_to(:edit, Role) }
    it { is_expected.not_to be_able_to(:create, Role) }

  end
end
