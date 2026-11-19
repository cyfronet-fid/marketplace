# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Backoffice: the exit modal of the offer form", :backend do
  let(:coordinator) { create(:user, roles: [:coordinator]) }
  let(:service) { create(:service) }

  before do
    login_as(coordinator)
    get new_backoffice_service_offer_path(service)
  end

  it "renders the form" do
    expect(response).to have_http_status(:ok)
  end

  # The controller reads the name of the button, not its label.
  it "names the submit button of the draft" do
    expect(response.body).to include('<input type="submit" name="save_as_draft" value="Save as draft"')
  end

  it "labels the exit link" do
    expect(response.body).to include("Exit without saving")
  end
end
