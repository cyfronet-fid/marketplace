# frozen_string_literal: true

class OrderingApi::TriggersTestSetup
  def initialize; end

  def call
    oms_admin = User.find_by!(uid: "iamasomboadmin")

    oms1 = OMS.find_by!(default: true)
    oms1.update!(trigger_url: "http://localhost:1080/oms1")
    oms2 = OMS.create!(name: "OMS2", type: "global", administrators: [oms_admin], trigger_url: "http://localhost:1080/oms2")
    oms3 = OMS.create!(name: "OMS3", type: "global", administrators: [oms_admin], trigger_url: "http://localhost:1080/oms3")

    provider = Provider.create!(name: "provider")
    service1 = Service.create!(name: "s1", description: "asd", tagline: "asd", status: "published", providers: [provider],
                         resource_organisation: provider, scientific_domains: [ScientificDomain.first], geographical_availabilities: ["PL"])
    service2 = Service.create!(name: "s2", description: "asd", tagline: "asd", status: "published", providers: [provider],
                         resource_organisation: provider, scientific_domains: [ScientificDomain.first], geographical_availabilities: ["PL"])
    Offer.create!(name: "s1_o", order_type: "open_access", description: "asd", service: service1,
                  status: "published", primary_oms: oms2)
    Offer.create!(name: "s2_o", order_type: "open_access", description: "asd", service: service2,
                  status: "published", primary_oms: oms3)

    # The test scenario:
    # Create project p1 (triggers: OMS1)
    # Write a message in p1 (triggers: OMS1)
    # Create project_item pi1_1 from s1_o (triggers: OMS1, OMS2)
    # Write a message in pi1_1 (triggers: OMS1, OMS2)
    # Write a message in p1 (triggers: OMS1, OMS2)
    # Create project_item pi1_2 from s2_o (triggers: OMS1, OMS3)
    # Write a message in pi1_2 (triggers: OMS1, OMS3)
    # Write a message in p1 (triggers: OMS1, OMS2, OMS3)
  end
end
