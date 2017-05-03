require 'rails_helper'

RSpec.describe User do

  let(:guest) { FactoryGirl.build(:user) }

  describe "a guest user" do
    it "is not registered" do
      expect(guest.staff?).to eq false
    end
  end
end
