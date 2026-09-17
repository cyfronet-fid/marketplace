# frozen_string_literal: true

require "rails_helper"
require "ordering_api/add_sombo"

describe OrderingApi::AddSombo, :backend do
  it "creates SOMBO OMS and adds SOMBO admin to it" do
    described_class.new.call

    expect(User.count).to eq(1)
    expect(User.first.first_name).to eq("SOMBO admin")
    expect(OMS.count).to eq(1)
    expect(OMS.first.name).to eq("SOMBO")
    expect(OMS.first.administrators.first.first_name).to eq("SOMBO admin")
  end

  it "doesn't create SOMBO OMS and SOMBO admin if they exist" do
    admin =
      create(
        :user,
        first_name: "SOMBO admin",
        last_name: "SOMBO admin",
        email: "sombo@sombo.com",
        uid: "iamasomboadmin"
      )
    create(:oms, name: "SOMBO", administrators: [admin])

    described_class.new.call

    expect(User.count).to eq(1)
    expect(User.first.first_name).to eq("SOMBO admin")
    expect(OMS.count).to eq(1)
    expect(OMS.first.name).to eq("SOMBO")
    expect(OMS.first.administrators.first.first_name).to eq("SOMBO admin")
  end

  it "creates SOMBO OMS, SOMBO admin relationship if they exist" do
    sombo_admin =
      create(
        :user,
        first_name: "SOMBO admin",
        last_name: "SOMBO admin",
        email: "sombo@sombo.com",
        uid: "iamasomboadmin"
      )
    create(:oms, name: "SOMBO")

    described_class.new.call

    expect(OMS.count).to eq(1)
    OMS.all.each do |sombo|
      expect(sombo.administrators.count).to eq(3)
      expect(sombo.administrators).to include(sombo_admin)
    end
  end

  # pl resolves the SOMBO admin through a checkin identity (see below).
  it "creates SOMBO OMS, SOMBO admin relationship if SOMBO exists and admin doesn't", variant: :marketplace do
    create(:oms, name: "SOMBO")

    described_class.new.call

    expect(OMS.count).to eq(1)
    OMS.all.each do |sombo|
      expect(sombo.administrators.count).to eq(3)
      expect(sombo.administrators).to include(User.find_by(uid: "iamasomboadmin"))
    end
  end

  context "when running as pl" do
    subject(:sombo_admin) { UserIdentity.find_by(provider: "checkin", uid: "iamasomboadmin").user }

    before do
      allow(Mp::Variant).to receive(:pl?).and_return(true)
      described_class.new.call
    end

    it "creates the SOMBO admin through a checkin identity" do
      expect(sombo_admin.first_name).to eq("SOMBO admin")
    end

    it "gives the SOMBO admin every role" do
      expect(sombo_admin.roles_mask).to eq(7)
    end

    it "adds the SOMBO admin to the SOMBO OMS" do
      expect(OMS.find_by(name: "SOMBO").administrators).to include(sombo_admin)
    end
  end
end
