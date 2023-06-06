# frozen_string_literal: true

require "rails_helper"

RSpec.describe MainContact, type: :model, backend: true do
  it { should validate_presence_of(:email) }
  it { should belong_to(:contactable) }
end
