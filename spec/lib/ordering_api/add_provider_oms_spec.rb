# frozen_string_literal: true

require "rails_helper"
require "ordering_api/add_provider_oms"

describe OrderingApi::AddProviderOMS, backend: true do
  let!(:provider) { create(:provider, pid: "test.pid") }
  let!(:another_provider) { create(:provider, pid: "another.pid") }
  let(:service) { create(:service, resource_organisation: provider) }

  it "fails if provider is not found" do
    expect(provider.omses.count).to eq(0)

    described_class.new("name", "other.pid", "token").call

    expect(provider.omses.count).to eq(0)
  end

  it "creates OMS and adds admin to it" do
    expect(provider.omses.count).to eq(0)

    described_class.new("test_provider", "test.pid", "token_value").call

    expect(provider.omses.count).to eq(1)

    expect(User.count).to eq(1)
    expect(User.first.first_name).to eq("Test Provider")
    expect(User.first.authentication_token).to eq("token_value")
    expect(OMS.count).to eq(1)
    expect(OMS.first.name).to eq("Test Provider OMS")
    expect(OMS.first.administrators.first.first_name).to eq("Test Provider")
    expect(service.available_omses).to contain_exactly(OMS.first)
  end

  it "updates token if user exists and creates provider-OMS relationship" do
    admin = create(:user, uid: "iamatest_provideradmin")
    create(:oms, name: "Test Provider OMS", administrators: [admin])

    expect(User.count).to eq(1)
    expect(admin.authentication_token).not_to eq("token_value")
    expect(provider.omses.count).to eq(0)

    described_class.new("test_provider", "test.pid", "token_value").call

    expect(User.count).to eq(1)
    expect(admin.reload.authentication_token).to eq("token_value")
    expect(provider.omses.count).to eq(1)
  end

  it "can be called multiply to add providers to OMS and update token" do
    described_class.new("test_provider", "test.pid", "token_value").call

    expect(OMS.first.providers.count).to eq(1)

    expect(User.count).to eq(1)
    expect(User.first.first_name).to eq("Test Provider")
    expect(User.first.authentication_token).to eq("token_value")
    expect(OMS.count).to eq(1)
    expect(OMS.first.name).to eq("Test Provider OMS")
    expect(OMS.first.administrators.first.first_name).to eq("Test Provider")

    described_class.new("test_provider", "another.pid", "new_token").call

    expect(OMS.first.providers.count).to eq(2)

    expect(User.count).to eq(1)
    expect(User.first.first_name).to eq("Test Provider")
    expect(User.first.authentication_token).to eq("new_token")
    expect(OMS.count).to eq(1)
    expect(OMS.first.name).to eq("Test Provider OMS")
    expect(OMS.first.administrators.first.first_name).to eq("Test Provider")
  end
end
