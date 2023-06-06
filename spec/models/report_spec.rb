# frozen_string_literal: true

require "rails_helper"

RSpec.describe Report, backend: true do
  subject { Report.new(text: "text", author: build(:user)) }

  it { should validate_presence_of(:text).with_message("Description cannot be blank") }
  it { should validate_presence_of(:author) }
  it { should validate_presence_of(:email) }
end
