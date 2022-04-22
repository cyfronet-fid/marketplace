# frozen_string_literal: true

require "rails_helper"
require_relative "publishable"

RSpec.describe User do
  include_examples "publishable"

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

  # This is relevant for users who where created before introducing simple_token_authentication, they will have null
  # authentication_tokens.
  context "#valid_token?" do
    it "is false when token is nil" do
      user = build(:user)

      expect(user.valid_token?).to be false
    end

    it "is false when token is empty" do
      user = build(:user_with_empty_token)

      expect(user.valid_token?).to be false
    end

    it "is true when token is present" do
      user = build(:user_with_token)

      expect(user.valid_token?).to be true
    end
  end

  context "OMS validations" do
    subject { build(:user, administrated_omses: build_list(:oms, 2)) }
    it { should have_many(:administrated_omses) }
  end

  context "authentication_token" do
    it "is present when creating new user" do
      user = create(:user)
      expect(user.authentication_token).to be_truthy
    end
  end
end
