# frozen_string_literal: true

require "rails_helper"

RSpec.describe OMS::Trigger, type: :model, backend: true do
  it { should belong_to(:oms) }
  it { should have_one(:authorization).dependent(:destroy) }

  it { should validate_presence_of(:url) }
  it { should validate_presence_of(:method) }
end
