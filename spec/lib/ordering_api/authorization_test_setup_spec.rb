# frozen_string_literal: true

require "rails_helper"
require "ordering_api/authorization_test_setup"

describe OrderingApi::AuthorizationTestSetup, :backend do
  let!(:scientific_domain) { create(:scientific_domain) }
  let!(:category) { create(:category) }
  let!(:service_category) { create(:service_category) }

  context "when running as marketplace" do
    before do
      allow(Mp::Variant).to receive_messages(marketplace?: true, pl?: false, whitelabel?: false)
      described_class.new.call
    end

    it "creates the sample services" do
      expect(Service.pluck(:name)).to contain_exactly("s1", "s2")
    end

    it "creates the OMSes" do
      expect(OMS.pluck(:name)).to contain_exactly("OMS2", "OMS3")
    end

    it "creates the project items" do
      expect(ProjectItem.count).to eq(3)
    end

    it "does not create PL profiles" do
      expect(Service::PlProfile.count).to eq(0)
    end
  end

  context "when running as pl" do
    before do
      allow(Mp::Variant).to receive_messages(marketplace?: false, pl?: true, whitelabel?: false)
      described_class.new.call
    end

    it "creates the sample services" do
      expect(Service.pluck(:name)).to contain_exactly("s1", "s2")
    end

    it "creates the OMSes" do
      expect(OMS.pluck(:name)).to contain_exactly("OMS2", "OMS3")
    end

    it "creates the project items" do
      expect(ProjectItem.count).to eq(3)
    end

    it "stores the tagline in the PL profile" do
      expect(Service.find_by(name: "s1").tagline).to eq("asd")
    end

    it "sets the geographical availability" do
      expect(Service.find_by(name: "s1").geographical_availabilities.map(&:alpha2)).to eq(["PL"])
    end

    it "creates the users with their login identities" do
      expect(UserIdentity.pluck(:uid)).to contain_exactly("oms2_admin", "oms3_admin", "user")
    end
  end

  context "when running as whitelabel" do
    before do
      allow(Mp::Variant).to receive_messages(marketplace?: false, pl?: false, whitelabel?: true)
      described_class.new.call
    end

    it "creates the sample services" do
      expect(Service.pluck(:name)).to contain_exactly("s1", "s2")
    end

    it "creates the OMSes" do
      expect(OMS.pluck(:name)).to contain_exactly("OMS2", "OMS3")
    end

    it "creates the project items" do
      expect(ProjectItem.count).to eq(3)
    end

    it "sets the geographical availability" do
      expect(Service.find_by(name: "s1").geographical_availabilities.map(&:alpha2)).to eq(["PL"])
    end

    it "does not create PL profiles" do
      expect(Service::PlProfile.count).to eq(0)
    end
  end
end
