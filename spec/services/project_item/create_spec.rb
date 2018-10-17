# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProjectItem::Create do
  let(:user) { create(:user) }
  let(:service) { create(:service) }
  let(:project_item_template) { build(:project_item, user: user, service: service) }

  it "creates project_item and set initial project_item change" do
    project_item = described_class.new(project_item_template).call

    expect(project_item).to be_created
    expect(project_item.user).to eq(user)
    expect(project_item.service).to eq(service)
  end

  it "creates first project_item change" do
    project_item = described_class.new(project_item_template).call

    expect(project_item.project_item_changes.count).to eq(1)
    expect(project_item.project_item_changes.first).to be_created
  end

  it "triggers register project_item in external system" do
    project_item = described_class.new(project_item_template).call

    expect(ProjectItem::RegisterJob).to have_been_enqueued.with(project_item)
  end

  it "sends email to project_item owner" do
    expect { described_class.new(project_item_template).call }.
      to change { ActionMailer::Base.deliveries.count }.by(1)
  end
end
