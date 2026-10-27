# frozen_string_literal: true

require "rails_helper"

RSpec.describe Infrastructure::ProjectItemStatus, type: :service do
  let(:project_item) { create(:project_item, status: "created", status_type: :created) }

  describe ".ready!" do
    before { described_class.ready!(project_item, "https://hub.example.com") }

    it "marks the project item ready with the deployment link" do
      expect(project_item.reload).to have_attributes(
        status_type: "ready",
        status: "Deployment ready at https://hub.example.com",
        deployment_link: "https://hub.example.com"
      )
    end
  end

  describe ".rejected!" do
    before do
      project_item.update!(deployment_link: "https://hub.example.com")
      described_class.rejected!(project_item, "Deployment failed: boom. Please contact support.")
    end

    it "marks the project item rejected with the message" do
      expect(project_item.reload).to have_attributes(
        status_type: "rejected",
        status: "Deployment failed: boom. Please contact support."
      )
    end

    it "removes the link to the failed deployment" do
      expect(project_item.reload.deployment_link).to be_nil
    end
  end

  describe ".closed!" do
    before { described_class.closed!(project_item) }

    it "marks the project item closed" do
      expect(project_item.reload).to have_attributes(status_type: "closed", status: "Infrastructure has been destroyed")
    end
  end
end
