# frozen_string_literal: true

require "rails_helper"
require "ordering_api/add_sombo"

describe OrderingApi::AddSombo do
  it "creates SOMBO OMS and adds SOMBO admin to it" do
    described_class.new.call

    expect(User.count).to eq(1)
    expect(User.first.first_name).to eq("SOMBO admin")
    expect(OMS.count).to eq(1)
    expect(OMS.first.name).to eq("SOMBO")
    expect(OMS.first.administrators.first.first_name).to eq("SOMBO admin")
  end

  it "doesn't create SOMBO OMS and SOMBO admin if they exist" do
    admin = create(:user, first_name: "SOMBO admin", last_name: "SOMBO admin", email: "sombo@sombo.com", uid: "iamasomboadmin")
    create(:oms, name: "SOMBO", type: :global, default: true, custom_params: { order_target: { mandatory: false } }, administrators: [admin])
    described_class.new.call

    expect(User.count).to eq(1)
    expect(User.first.first_name).to eq("SOMBO admin")
    expect(OMS.count).to eq(1)
    expect(OMS.first.name).to eq("SOMBO")
    expect(OMS.first.administrators.first.first_name).to eq("SOMBO admin")
  end

  it "updates offers' oms_params properly" do
    offer1 = create(:offer, primary_oms: nil, service: create(:service, order_target: "admin@admin.pl"))
    service = create(:service, order_target: "data@data.pl")
    offer2 = create(:offer, primary_oms: nil, service: service)

    described_class.new.call
    offer1.reload
    offer2.reload

    expect(offer1.current_oms).to eql(OMS.find_by(default: true))
    expect(offer1.current_oms.name).to eql("SOMBO")
    expect(offer1.oms_params.symbolize_keys).to eql({ order_target: "admin@admin.pl" })

    expect(offer2.current_oms).to eql(OMS.find_by(default: true))
    expect(offer2.current_oms.name).to eql("SOMBO")
    expect(offer2.oms_params.symbolize_keys).to eql({ order_target: "data@data.pl" })

    new_oms = create(:oms, custom_params: { a: { mandatory: true, default: "asd" } })
    offer1.update(primary_oms: new_oms, oms_params: { a: "qwe" })
    service.update(order_target: "qwe@qwe.pl")

    described_class.new.call
    offer1.reload
    offer2.reload

    expect(offer1.current_oms).to eql(new_oms)
    expect(offer1.oms_params.symbolize_keys).to eql({ a: "qwe" })

    expect(offer2.current_oms).to eql(OMS.find_by(default: true))
    expect(offer2.current_oms.name).to eql("SOMBO")
    expect(offer2.oms_params.symbolize_keys).to eql({ order_target: "qwe@qwe.pl" })
  end
end
