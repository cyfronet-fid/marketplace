# frozen_string_literal: true

require "rails_helper"

RSpec.describe ServiceRelatedPlatform, type: :model, backend: true do
  it { should belong_to(:service) }
  it { should belong_to(:platform) }
  it { should validate_presence_of(:service) }
  it { should validate_presence_of(:platform) }
end
