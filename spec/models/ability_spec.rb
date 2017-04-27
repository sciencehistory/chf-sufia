require 'rails_helper'
require 'cancan/matchers'

RSpec.describe Ability do
  let(:staff) { FactoryGirl.create(:user) }
  let(:admin) { FactoryGirl.create(:user, :admin) }
  let(:staff_work) { FactoryGirl.create(:work, user: staff) }
  let(:admin_work) { FactoryGirl.create(:work, user: admin) }
  let(:solr_document) { SolrDocument.new(staff_work.to_solr) }

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

    it "cannot delete any work" do
      expect(staff).not_to be_able_to(:destroy, admin_work)
      expect(staff).not_to be_able_to(:destroy, staff_work)
      expect(staff).not_to be_able_to(:destroy, solr_document)
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
