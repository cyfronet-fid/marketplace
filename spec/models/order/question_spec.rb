# frozen_string_literal: true

require "rails_helper"

RSpec.describe Order::Question do
  subject { Order::Question.new(text: "text", author: build(:user), order: build(:order)) }

  it { should validate_presence_of(:text).with_message("Question cannot be blank") }
  it { should validate_presence_of(:author) }
  it { should validate_presence_of(:order) }
end
