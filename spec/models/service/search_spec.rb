# frozen_string_literal: true

require "rails_helper"

RSpec.describe Service::Search, :backend do
  describe "#search_data" do
    let(:research_activity) { create(:research_activity) }
    let(:target_user) { create(:target_user) }
    let(:platform) { create(:platform) }

    before { allow(Mp::Variant).to receive(:pl?).and_return(pl_variant) }

    context "for the PL variant" do
      let(:pl_variant) { true }

      it "indexes PL profile fields and retained associations" do
        service =
          create(
            :service,
            tagline: "PL research service",
            geographical_availabilities: %w[PL EU],
            research_activities: [research_activity],
            platforms: [platform],
            target_users: [target_user]
          )

        expect(service.search_data).to include(
          tagline: "PL research service",
          geographical_availabilities: %w[PL EU],
          research_activities: [research_activity.id],
          platforms: [platform.id],
          dedicated_for: [target_user.id]
        )
      end
    end

    context "for another variant" do
      let(:pl_variant) { false }

      it "does not change the V6 search document shape" do
        search_data = build(:service).search_data

        expect(search_data).not_to include(
          :tagline,
          :geographical_availabilities,
          :research_activities,
          :platforms,
          :dedicated_for
        )
      end
    end
  end
end
