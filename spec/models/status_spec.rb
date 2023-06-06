# frozen_string_literal: true

require "rails_helper"

RSpec.describe Status, backend: true do
  it { should belong_to(:status_holder) }
  it { should validate_presence_of(:status) }
  it { should validate_presence_of(:status_type) }
end
