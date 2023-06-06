# frozen_string_literal: true

require "rails_helper"

RSpec.describe ScientificDomainsHelper, type: :helper, backend: true do
  context "#grouped_scientific_domain" do
    it "groups scientific domains" do
      root1, root2 = create_list(:scientific_domain, 2)
      leaf1, leaf2 = create_list(:scientific_domain, 2, parent: root1)

      groupped = grouped_scientific_domains

      expect(groupped[0]).to eq(["/", [root2]])
      expect(groupped[1]).to eq(["/#{root1.name}/", [leaf1, leaf2]])
    end
  end
end
