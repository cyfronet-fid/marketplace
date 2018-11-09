# frozen_string_literal: true

require "rails_helper"

RSpec.describe AffiliationPolicy do
  let(:user) { create(:user) }

  subject { described_class }

  permissions :index?, :create? do
    it "grants access for logged in user" do
      expect(subject).to permit(user)
    end
  end

  permissions :edit?, :update? do
    context "not confirmed affiliation" do
      it "grants access for affiliation user" do
        expect(subject).to permit(user, build(:affiliation, user: user))
      end

      it "denies to see other user owners" do
        expect(subject).to_not permit(user, build(:affiliation))
      end
    end

    context "confirmed affiliation" do
      it "denies even for affiliation owner" do
        expect(subject).to_not permit(user, build(:affiliation, status: :active))
      end
    end
  end

  permissions :destroy? do
    it "grants access for affiliation user" do
      expect(subject).to permit(user, build(:affiliation, user: user))
    end

    it "denies to destroy a not owned affiliation" do
      expect(subject).to_not permit(user, build(:affiliation))
    end

    it "denies to destroy an owned affiliation which has any project item" do
      affiliation = create(:affiliation, user: user)
      create(:project_item, affiliation: affiliation)
      expect(subject).to_not permit(user, affiliation)
    end
  end

  it "returns only user affiliations" do
    owned_affiliation = create(:affiliation, user: user)
    _other_user_affiliation = create(:affiliation)

    scope = described_class::Scope.new(user, Affiliation.all)

    expect(scope.resolve).to contain_exactly(owned_affiliation)
  end
end
