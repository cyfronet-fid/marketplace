# frozen_string_literal: true

require "rails_helper"

RSpec.describe UsageReport do
  context ".orderable_count" do
    it "counts orderable services with published offer" do
      s1 = create(:service, status: :published)
      s2 = create(:service, status: :published)
      s3 = create(:service, status: :unverified)
      s4 = create(:service, status: :draft)
      create(:offer, service: s1, order_type: :orderable, status: :draft)
      create(:offer, service: s1, order_type: :open_access, status: :published)
      create(:offer, service: s1, order_type: :external, status: :published)
      create(:offer, service: s2, order_type: :orderable, status: :published)
      create(:offer, service: s3, order_type: :orderable, status: :published)
      create(:offer, service: s4, order_type: :orderable, status: :published)

      expect(subject.orderable_count).to eq(2)
    end
  end

  context ".not_orderable_count" do
    it "counts open access and external services with published offer" do
      s1 = create(:service, status: :published)
      s2 = create(:service, status: :published)
      s3 = create(:service, status: :unverified)
      s4 = create(:service, status: :draft)
      create(:offer, service: s1, order_type: :orderable, status: :published)
      create(:offer, service: s1, order_type: :open_access, status: :draft)
      create(:offer, service: s1, order_type: :external, status: :draft)
      create(:offer, service: s2, order_type: :open_access, status: :published)
      create(:offer, service: s3, order_type: :external, status: :published)
      create(:offer, service: s4, order_type: :external, status: :published)

      expect(subject.not_orderable_count).to eq(2)
    end
  end

  context ".all_services_count" do
    it "counts all published and unverified services" do
      create(:service, status: :published)
      create(:service, status: :unverified)
      create(:service, status: :draft)

      expect(subject.all_services_count).to eq(2)
    end
  end

  context ".providers" do
    it "returns providers names" do
      create(:provider, name: "p1")
      create(:provider, name: "p2")

      expect(subject.providers).to contain_exactly("p1", "p2")
    end
  end

  context ".disciplines" do
    it "returns disciplines from projects with services" do
      ra1, ra2, ra3 = create_list(:research_area, 3)
      create(:project, research_areas: [ra1])
      p = create(:project, research_areas: [ra2, ra3])
      create(:project_item, project: p)

      expect(subject.disciplines).to contain_exactly(ra2.name, ra3.name)
    end
  end

  context ".countries" do
    it "returns countries from projects with services" do
      create(:project, country_of_origin: "gb")
      p = create(:project, country_of_origin: "pl")
      create(:project_item, project: p)

      expect(subject.countries).to contain_exactly("Poland")
    end
  end
end
