# frozen_string_literal: true

require "rails_helper"
require "bcrypt"

RSpec.describe Users::AuthMockController, type: :controller, end_user_backend: true do
  controller { attr_accessor :params }

  before(:each) do
    @body = { email: "test@mail.com", password: "test123" }
    controller.params = ActionController::Parameters.new(@body)
    @user = create(:user, email: @body[:email])
  end

  it "should skip login on non development environment" do
    allow(Mp::Application.config).to receive(:auth_mock).and_return(true)
    allow(Rails.env).to receive(:development?).and_return(false)
    expect(User).not_to receive(:find_by)

    controller.login
  end

  it "should skip login on missing auth mock env variable" do
    allow(Mp::Application.config).to receive(:auth_mock).and_return(false)
    allow(Rails.env).to receive(:development?).and_return(true)
    expect(User).not_to receive(:find_by)

    controller.login
  end
end
