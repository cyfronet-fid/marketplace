# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Backoffice scientific domain", backend: true do
  context "as a logged in service portfolio manager" do
    let(:user) { create(:user, roles: [:coordinator]) }

    before { login_as(user) }

    it "I can delete scientific domain" do
      scientific_domain = create(:scientific_domain)

      expect { delete backoffice_other_settings_scientific_domain_path(scientific_domain) }.to change {
        ScientificDomain.count
      }.by(-1)
    end
  end
end
