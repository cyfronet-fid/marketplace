# frozen_string_literal: true

require "rails_helper"

RSpec.describe User do
  it { should validate_presence_of(:first_name) }
  it { should validate_presence_of(:last_name) }
  it { should validate_presence_of(:email) }
  it { should validate_presence_of(:uid) }

  it { should have_many(:projects).dependent(:destroy) }

  context "#full_name" do
    it "is composed from first and last name" do
      user = build(:user, first_name: "John", last_name: "Rambo")

      expect(user.full_name).to eq "John Rambo"
    end
  end

  context "#email" do
    it "two users with the same emails are created" do
      email = "rambo@john.eu"
      u1 = build(:user, first_name: "john", last_name: "rambo", email: email)
      u2 = build(:user, first_name: "johny", last_name: "rambo", email: email)
      expect(u1.save).to be true
      expect(u2.save).to be true
    end
  end

  context "#service_owner?" do
    it "is false when user does not own any services" do
      user = create(:user)

      expect(user).to_not be_service_owner
    end

    it "is true when user owns services" do
      user = create(:user)
      service = create(:service)
      ServiceUserRelationship.create!(user: user, service: service)

      expect(user).to be_service_owner
    end
  end
end
