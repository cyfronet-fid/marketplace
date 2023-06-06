# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::AdminPolicy, backend: true do
  subject { described_class }

  permissions :show? do
    it "grants access for admin" do
      expect(subject).to permit(build(:user, roles: [:admin]), %i[admin admin])
    end

    it "denies for normal user" do
      expect(subject).to_not permit(build(:user), %i[admin admin])
    end
  end
end
