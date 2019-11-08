# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProjectItem::Create do
  let(:user) { create(:user) }
  let(:project) { create(:project, user: user) }
  let(:service) { create(:service) }
  let(:offer) { create(:offer, service: service) }
  let(:project_item_template) { build(:project_item, project: project, offer: offer) }

  it "creates project_item and set initial project_item status" do
    project_item = described_class.new(project_item_template).call

    expect(project_item).to be_created
    expect(project_item.user).to eq(user)
    expect(project_item.service).to eq(service)
  end

  it "creates first project_item status" do
    project_item = described_class.new(project_item_template).call

    expect(project_item.statuses.count).to eq(1)
    expect(project_item.statuses.first).to be_created
  end

  it "triggers register project_item in external system" do
    project_item = described_class.new(project_item_template).call

    expect(ProjectItem::RegisterJob).to have_been_enqueued.with(project_item)
  end

  context "when open_access service has been added to Project" do
    it "not sends email to project_item owner" do
      service = create(:open_access_service)
      offer = create(:offer, service: service)
      project_item_template = build(:project_item, project: project, offer: offer)

      expect { described_class.new(project_item_template).call }.
        to_not change { ActionMailer::Base.deliveries.count }
    end
  end

  context "when external service has been added to Project" do
    it "not sends email to project_item owner" do
      service = create(:external_service)
      offer = create(:offer, service: service)
      project_item_template = build(:project_item, project: project, offer: offer)

      expect { described_class.new(project_item_template).call }.
        to_not change { ActionMailer::Base.deliveries.count }
    end
  end


  context "when orderable service has been ordered" do
    it "sends email to project_item owner" do
      expect { described_class.new(project_item_template).call }.
        to change { ActionMailer::Base.deliveries.count }.by(1)
    end
  end
end
