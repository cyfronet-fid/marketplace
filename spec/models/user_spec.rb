# frozen_string_literal: true

require "rails_helper"
require_relative "publishable"

RSpec.describe User, backend: true do
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

  %i[catalogue provider].each do |model|
    context "#{model}_owner?" do
      it "connects created user to #{model} through user hooks" do
        user = build(:user)
        data_administrators = build_list(:data_administrator, 2, email: user.email)
        data_administrators.each { |data_administrator| create(model, data_administrators: [data_administrator]) }
        user.save
        user.reload
        data_administrators.each do |data_administrator|
          data_administrator.reload
          expect(data_administrator.user_id).to eq(user.id)
        end
        expect(user.send("#{model}s_count")).to eq(2)
      end

      it "connects created data administrator to existing user" do
        user = create(:user)
        data_administrators = build_list(:data_administrator, 2, email: user.email)
        data_administrators.each { |data_administrator| create(model, data_administrators: [data_administrator]) }
        user.reload
        data_administrators.each { |data_administrator| expect(data_administrator.user_id).to eq(user.id) }
        expect(user.send("#{model}s_count")).to eq(2)
      end

      it "connects updated data administrator to existing user" do
        user = create(:user)
        data_administrators = build_list(:data_administrator, 3)
        data_administrators.each { |data_administrator| create(model, data_administrators: [data_administrator]) }

        expect(user.send("#{model}s_count")).to eq(0)

        data_administrators.each do |data_administrator|
          data_administrator.update(email: user.email)
          data_administrator.reload
          expect(data_administrator.user_id).to eq(user.id)
        end
        user.reload
        expect(user.send("#{model}s_count")).to eq(3)
      end

      it "removes connection for #{model}'s updated data_administrator" do
        user = create(:user)
        data_administrators = build_list(:data_administrator, 3, email: user.email)
        data_administrators.each do |data_administrator|
          create(model, data_administrators: [data_administrator])
          data_administrator.reload
          expect(data_administrator.user_id).to eq(user.id)
        end
        user.reload
        expect(user.send("#{model}s_count")).to eq(3)

        last = data_administrators.last
        last.update(email: "some@mail.com")
        last.reload
        expect(last.user_id).to eq(nil)
        user.reload
        expect(user.send("#{model}s_count")).to eq(2)
      end

      it "removes connection for #{model}'s removed data_administrator" do
        user = create(:user)
        data_administrators = build_list(:data_administrator, 2)
        user_data_administrator = build(:data_administrator, email: user.email)
        managed = create(model, data_administrators: data_administrators << user_data_administrator)

        expect(managed.data_administrators.map(&:user_id)).to include(user.id)
        user.reload
        expect(user.send("#{model}s_count")).to eq(1)
        user_data_administrator.destroy
        user.reload
        expect(user.send("#{model}s_count")).to eq(0)
      end
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
