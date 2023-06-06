# frozen_string_literal: true

require "rails_helper"

RSpec.describe Service::Question, backend: true do
  subject { Service::Question.new(text: "text", author: build(:user), service: build(:service)) }

  it { should validate_presence_of(:text).with_message("Question cannot be blank") }
  it { should validate_presence_of(:author) }
  it { should validate_presence_of(:service) }
end
