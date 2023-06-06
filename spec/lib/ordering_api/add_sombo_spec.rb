# frozen_string_literal: true

require "rails_helper"
require "ordering_api/add_sombo"

describe OrderingApi::AddSombo, backend: true do
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

  it "creates SOMBO OMS, SOMBO admin relationship if SOMBO exists and admin doesn't" do
    create(:oms, name: "SOMBO")

    described_class.new.call

    expect(OMS.count).to eq(1)
    OMS.all.each do |sombo|
      expect(sombo.administrators.count).to eq(3)
      expect(sombo.administrators).to include(User.find_by(uid: "iamasomboadmin"))
    end
  end
end
