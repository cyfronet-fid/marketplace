# frozen_string_literal: true

require "rails_helper"

RSpec.describe OMS::Trigger, type: :model do
  it { should belong_to(:oms) }

  it { should validate_presence_of(:url) }
  it { should validate_presence_of(:method) }
end
