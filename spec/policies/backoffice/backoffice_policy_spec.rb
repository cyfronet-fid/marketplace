# frozen_string_literal: true

require "rails_helper"

RSpec.describe Backoffice::BackofficePolicy, backend: true do
  subject { described_class }

  permissions :show? do
    it "grants access for service owner" do
      expect(subject).to permit(build(:user, roles: [:coordinator]), %i[backoffice backoffice])
    end

    it "denies for normal user" do
      expect(subject).to_not permit(build(:user), %i[backoffice backoffice])
    end
  end
end
