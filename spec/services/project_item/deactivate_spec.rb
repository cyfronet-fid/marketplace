# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProjectItem:: Deactivate do
  let(:user) { create(:user) }
  let(:project) { create(:project, user: user) }
  let(:open_access_project_item) { create(:open_access_project_item, project: project) }

  it "creates new project_item change" do
    described_class.new(open_access_project_item).call

    expect(open_access_project_item.project_item_changes.last).to be_deactivated
  end

  it "changes project_item status into deactivate on success" do
    described_class.new(open_access_project_item).call

    expect(open_access_project_item).to be_deactivated
  end

  it "sent proper email to project owner" do
    open_access_project_item.new_change(status: :ready, message: "project_item has been deactivated")

    expect { described_class.new(open_access_project_item).call }.
      to change { ActionMailer::Base.deliveries.count }.by(1)
    email = ActionMailer::Base.deliveries.last

    expect(email.to).to eq([user.email])
    expect(email.subject).to eq("[ProjectItem ##{open_access_project_item.id}] status changed")
    expect(email.body.encoded).to match("was changed from \"ready\" to \"deactivated\"")
  end
end
