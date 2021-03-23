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

  context "#valid_token?" do
    it "is false when token is nil or 'revoked'" do
      user = create(:user)
      user.update(authentication_token: "revoked")

      expect(user.valid_token?).to be false

      # Workaround of the fact that 'simple_authentication_token' automatically generates token when you try to save
      # model object to database and model.authentication_token = nil.
      # Workaround is that we don't do 'user model.update(attribute: value)', but rather 'model.attribute = value'
      user.authentication_token = nil
      expect(user.valid_token?).to be false
    end

    it "is true when token is not nil or 'revoked'" do
      user = create(:user)
      expect(user.valid_token?).to be true
    end
  end

  context "OMS validations" do
    subject { build(:user, administrated_oms: build_list(:oms, 2)) }
    it { should have_many(:administrated_oms) }
  end

  context "authentication_token" do
    it "is present when creating new user" do
      user = create(:user)
      expect(user.authentication_token).to be_truthy
    end
  end

  context "#managed_services" do
    it "returns all managed services" do
      user = create(:user)
      data_administrator1 = create(:data_administrator, email: user.email)
      data_administrator2 = create(:data_administrator, email: user.email)
      service1 = create(:service, resource_organisation: create(:provider, data_administrators: [data_administrator1]))
      service2 = create(:service, resource_organisation: create(:provider, data_administrators: [data_administrator2]))

      expect(user.managed_services).to eq([service1, service2])
    end

    it "returns all managed services if there are any" do
      user = create(:user)
      data_administrator = create(:data_administrator, email: user.email)
      create(:provider, data_administrators: [data_administrator])

      expect(user.managed_services).to eq([])
    end

    it "returns all managed services if the user is a data admin" do
      regular_user = create(:user)
      data_admin_user = create(:user)
      data_administrator = create(:data_administrator, email: data_admin_user.email)
      service = create(:service, resource_organisation: create(:provider, data_administrators: [data_administrator]))

      expect(regular_user.managed_services).to eq([])
      expect(data_admin_user.managed_services).to eq([service])
    end
  end
end
