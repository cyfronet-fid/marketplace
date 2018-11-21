# frozen_string_literal: true

require "rails_helper"

RSpec.describe ServiceTargetGroup, type: :model do
  it { should belong_to(:service) }
  it { should belong_to(:target_group) }
  it { should validate_presence_of(:service) }
  it { should validate_presence_of(:target_group) }
end
