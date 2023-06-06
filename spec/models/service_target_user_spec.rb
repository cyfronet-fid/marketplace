# frozen_string_literal: true

require "rails_helper"

RSpec.describe ServiceTargetUser, type: :model, backend: true do
  it { should belong_to(:service) }
  it { should belong_to(:target_user) }
  it { should validate_presence_of(:service) }
  it { should validate_presence_of(:target_user) }
end
