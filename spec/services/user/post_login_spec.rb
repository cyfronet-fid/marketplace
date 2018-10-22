# frozen_string_literal: true

require "rails_helper"

RSpec.describe User::PostLogin do
  it "creates default project" do
    user = create(:user)

    described_class.new(user).call

    expect(user.projects.find_by(name: "Services")).to_not be_nil
  end
end
