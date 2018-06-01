# frozen_string_literal: true

require "rails_helper"

RSpec.describe User do
  context "#full_name" do
    it "is composed from first and last name" do
      user = build(:user, first_name: "John", last_name: "Rambo")

      expect(user.full_name).to eq "John Rambo"
    end
  end
end
