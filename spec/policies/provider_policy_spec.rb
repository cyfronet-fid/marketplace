# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProviderPolicy, backend: true do
  let(:user) { create(:user) }
  let(:stranger) { create(:user) }
  let(:data_administrator) { build(:data_administrator, email: user.email) }
  let(:provider) { create(:provider, data_administrators: [data_administrator]) }
  subject { described_class }

  def resolve
    subject::Scope.new(user, Provider).resolve
  end

  it "should deny removed provider" do
    create(:provider, status: :deleted)

    expect(resolve.count).to eq(0)
  end

  permissions :data_administrator? do
    it "grants access when data administrator" do
      expect(subject).to permit(user, provider)
    end

    it "denies when not data administrator" do
      expect(subject).to_not permit(stranger, provider)
    end

    it "denies when data administrator of another resource" do
      other_provider = create(:provider)
      expect(subject).to_not permit(user, other_provider)
    end
  end
end
