# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Adding an offer to a project" do
  subject(:add_to_project) do
    post service_summary_path(offer.service), params: { customizable_project_item: { project_id: project.id } }
  end

  let(:user) { create(:user) }
  let(:project) { create(:project, user: user) }
  let(:offer) { create(:offer) }

  before do
    allow(Checkin::CheckVoMembership).to receive(:call).and_return(
      Checkin::CheckVoMembership::CheckResult.new(status: :member)
    )
    sign_in(user)
    put service_choose_offer_path(offer.service), params: { customizable_project_item: { offer_id: offer.iid } }
  end

  it "creates the project item" do
    expect { add_to_project }.to change(project.project_items, :count).by(1)
  end
end
