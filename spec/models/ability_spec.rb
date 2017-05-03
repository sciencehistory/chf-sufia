require 'rails_helper'
require 'cancan/matchers'

RSpec.describe Ability do
  let(:staff) { FactoryGirl.create(:user) }
  let(:admin) { FactoryGirl.create(:user, :admin) }
  let(:guest) { FactoryGirl.build(:user) }
  let(:staff_work) { FactoryGirl.create(:work, user: staff) }
  let(:admin_work) { FactoryGirl.create(:work, user: admin) }
  let(:solr_document) { SolrDocument.new(staff_work.to_solr) }

  describe "a guest user" do
    it "cannot view user list or profiles" do
      expect(guest).not_to be_able_to(:read, User)
    end
  end

  describe "an unprivileged user" do
    it "is not an admin" do
      expect(staff.admin?).to eq false
    end

    it "cannot manage Roles" do
      expect(staff).not_to be_able_to(:read, Role)
      expect(staff).not_to be_able_to(:add_user, Role)
      expect(staff).not_to be_able_to(:remove_user, Role)
      expect(staff).not_to be_able_to(:destroy, Role)
      expect(staff).not_to be_able_to(:create, Role)
      expect(staff).not_to be_able_to(:edit, Role)
    end

    it "cannot delete any work" do
      expect(staff).not_to be_able_to(:destroy, admin_work)
      expect(staff).not_to be_able_to(:destroy, staff_work)
      expect(staff).not_to be_able_to(:destroy, solr_document)
    end

    it "cant view user list or profiles" do
      expect(staff).to be_able_to(:read, User)
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

    it "can delete anything" do
      expect(admin).to be_able_to(:destroy, staff_work)
      expect(admin).to be_able_to(:destroy, solr_document)
      expect(admin).to be_able_to(:destroy, 'id1235')
    end
  end
end
