# frozen_string_literal: true

require "rails_helper"

RSpec.describe ServicePolicy do
  let(:user) { create(:user) }
  let(:stranger) { create(:user) }
  let(:data_administrator) { create(:data_administrator, email: user.email) }
  let(:provider) { create(:provider, data_administrators: [data_administrator]) }
  let(:service) { create(:service, resource_organisation: provider) }

  subject { described_class }

  def resolve
    subject::Scope.new(user, Service).resolve
  end

  permissions :data_administrator? do
    it "grants access when data administrator" do
      expect(subject).to permit(user, service)
    end

    it "denies when not data administrator" do
      expect(subject).to_not permit(stranger, service)
    end

    it "denies when data administrator of another resource" do
      other_service = create(:service)
      expect(subject).to_not permit(user, other_service)
    end
  end
end
