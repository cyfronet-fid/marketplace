# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Users::AuthMockController", type: :request do
  let(:body) { { email: "test@mail.com", password: "test123" } }

  before { Rails.application.routes.draw { get "users/login" => "users/auth_mock#login" } }
  after { Rails.application.reload_routes! }

  it "skips login on non development environment" do
    allow(Mp::Application.config).to receive(:auth_mock).and_return(true)
    allow(Rails.env).to receive(:development?).and_return(false)
    expect(User).not_to receive(:find_by)

    get "/users/login", params: body

    expect(response).to have_http_status(:forbidden)
  end

  it "skips login on missing auth mock env variable" do
    allow(Mp::Application.config).to receive(:auth_mock).and_return(false)
    allow(Rails.env).to receive(:development?).and_return(true)
    expect(User).not_to receive(:find_by)

    get "/users/login", params: body

    expect(response).to have_http_status(:forbidden)
  end
end
