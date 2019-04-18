# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Service opinions" do
  context "for open access service" do
    it "shows user review" do
      user = create(:user, first_name: "John", last_name: "Doe")
      project = create(:project, user: user)
      service = create(:open_access_service)
      offer = create(:offer, service: service)
      project_item = create(:project_item, offer: offer, project: project)
      create(:service_opinion, project_item: project_item, opinion: "my opinion")

      visit service_opinions_path(service)

      expect(page).to have_content("John")
      expect(page).to have_content("D.")
      expect(page).to have_content("my opinion")
    end
  end
end
