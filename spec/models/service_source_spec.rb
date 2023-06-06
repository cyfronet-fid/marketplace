# frozen_string_literal: true

require "rails_helper"

RSpec.describe ServiceSource, type: :model, backend: true do
  it { should validate_presence_of(:eid) }
  it { should validate_presence_of(:source_type) }

  it { should belong_to(:service) }
end
