# frozen_string_literal: true

class OrderingApi::TriggersTestSetup
  def call
    oms_admin = User.find_by!(uid: "iamasomboadmin")

    oms1 = OMS.find_by!(default: true)
    add_trigger(oms1, url: "http://localhost:1080/oms1")
    oms2 = OMS.create!(name: "OMS2", type: "global", administrators: [oms_admin])
    add_trigger(oms2, url: "http://localhost:1080/oms2", method: :get)
    oms3 = OMS.create!(name: "OMS3", type: "global", administrators: [oms_admin])
    add_trigger(oms3, url: "http://localhost:1080/oms3", user: "magic", password: "mushroom")

    service = Service.find_by(name: "EGI Cloud compute")
    Offer.create!(
      name: "offer_oms_2",
      description: "asd",
      service: service,
      status: "published",
      order_type: :order_required,
      internal: true,
      primary_oms: oms2
    )
    Offer.create!(
      name: "offer_oms_3",
      description: "asd",
      service: service,
      status: "published",
      order_type: :order_required,
      internal: true,
      primary_oms: oms3
    )

    # The test scenario:
    # Create project p1 (triggers: OMS1)
    # Write a message in p1 (triggers: OMS1)
    # Create project_item pi1_1 from offer_oms_2 (triggers: OMS1, OMS2)
    # Write a message in pi1_1 (triggers: OMS1, OMS2)
    # Write a message in p1 (triggers: OMS1, OMS2)
    # Create project_item pi1_2 from offer_oms_2 (triggers: OMS1, OMS3)
    # Write a message in pi1_2 (triggers: OMS1, OMS3)
    # Write a message in p1 (triggers: OMS1, OMS2, OMS3)
  end

  private

  def add_trigger(oms, url:, method: :post, user: nil, password: nil)
    oms.trigger = OMS::Trigger.new(url: url, method: method)
    if user.present? && password.present?
      oms.trigger.authorization = OMS::Authorization::Basic.new(user: user, password: password)
    end
    oms.trigger
  end
end
