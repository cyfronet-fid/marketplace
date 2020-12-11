# frozen_string_literal: true

require "rails_helper"

RSpec.describe Api::V1::ApiPolicy do
  subject { described_class }

  permissions :show? do
    it "grants access for data administrator" do
      data_admin_user = create(:user)
      create(:data_administrator, email: data_admin_user.email)
      expect(subject).to permit(data_admin_user, [:token])
    end

    it "denies for normal user" do
      expect(subject).to_not permit(create(:user), [:token])
    end
  end
end
