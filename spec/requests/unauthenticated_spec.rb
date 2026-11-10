# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Unauthenticated user", :backend do
  it "is redirected to checkin" do
    get profile_path

    expect(response).to redirect_to(user_checkin_omniauth_authorize_path)
  end

  it "is not redirected if accessing root_path" do
    get root_path

    expect(response.status).to eq(200)
  end

  context "when accessing Backoffice services" do
    before { get backoffice_services_path }

    it "redirects to Check-In" do
      expect(response).to redirect_to(user_checkin_omniauth_authorize_path)
    end

    it "preserves the requested Backoffice page" do
      expect(request.session["user_return_to"]).to eq(backoffice_services_path)
    end
  end
end
