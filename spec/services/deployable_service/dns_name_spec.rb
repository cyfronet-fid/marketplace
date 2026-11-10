# frozen_string_literal: true

require "rails_helper"

RSpec.describe DeployableService::DnsName do
  describe ".generate" do
    it "generates a name in the generated format" do
      expect(described_class.generate).to match(/\A\h{8}-\h{4}-\h{4}-\h{4}-\h{12}\.vm\.fedcloud\.eu\z/)
    end

    it "generates a unique name on each call" do
      expect(described_class.generate).not_to eq(described_class.generate)
    end
  end

  describe ".generated?" do
    it "accepts a generated name" do
      expect(described_class).to be_generated(described_class.generate)
    end

    it "rejects names users could choose" do
      uuid = SecureRandom.uuid
      names = ["user.example.com", "#{uuid}.example.com", "#{uuid}.vm.fedcloud.eu.evil.com", nil]

      expect(names.map { |name| described_class.generated?(name) }).to all(be(false))
    end
  end

  describe ".input?" do
    it "recognizes DNS inputs" do
      ids = %w[dns_name kube_public_dns_name public_dns_name]

      expect(ids.map { |id| described_class.input?(id) }).to all(be(true))
    end

    it "rejects other inputs" do
      expect(described_class.input?("admin_password")).to be(false)
    end
  end
end
