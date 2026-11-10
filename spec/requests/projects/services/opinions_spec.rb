# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Rating a project item" do
  subject(:rate) do
    post project_service_opinion_path(project_item.project, project_item),
         params: { service_opinion: { service_rating: 4, order_rating: 5, opinion: "Works well" } }
  end

  let(:project_item) { create(:project_item, status: "ready", status_type: :ready) }

  before { sign_in(project_item.project.user) }

  it "saves the rating" do
    expect { rate }.to change(ServiceOpinion.where(project_item: project_item, service_rating: 4), :count).by(1)
  end

  it "redirects to the page of the project item" do
    expect(rate).to redirect_to(project_service_path(project_item.project, project_item))
  end
end
