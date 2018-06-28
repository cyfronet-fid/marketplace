# frozen_string_literal: true

require "rails_helper"

RSpec.describe "User affiliations" do
  context "as a logged in user" do
    let(:user) { create(:user) }

    before { login_as(user) }

    it "I can delete my affiliation" do
      affiliation = create(:affiliation, user: user)

      expect { delete profile_affiliation_path(affiliation) }.
        to change { user.affiliations.count }.by(-1)
    end
  end
end
