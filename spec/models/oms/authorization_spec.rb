# frozen_string_literal: true

require "rails_helper"

RSpec.describe OMS::Authorization, type: :model, backend: true do
  it { should belong_to(:trigger) }
end
