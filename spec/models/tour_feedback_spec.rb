# frozen_string_literal: true

require "rails_helper"

RSpec.describe TourFeedback, type: :model, backend: true do
  it "it should save" do
    TourFeedback.new(
      controller_name: "controller_name",
      action_name: "index",
      tour_name: "tour",
      user_id: nil,
      email: "email@mail",
      content: {
        "comment" => "lorem ipsum",
        "rating" => 2
      }
    ).save!
  end
end
