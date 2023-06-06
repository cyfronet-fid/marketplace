# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Unauthenticated user", backend: true do
  it "should be redirected to checkin" do
    get profile_path

    expect(response).to redirect_to(user_checkin_omniauth_authorize_path)
  end

  it "should not be redirected if accessing root_path" do
    get root_path

    expect(response.status).to eq(200)
  end
end
