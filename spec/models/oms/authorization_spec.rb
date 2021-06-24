# frozen_string_literal: true

require "rails_helper"

RSpec.describe OMS::Authorization, type: :model do
  it { should belong_to(:trigger) }
end
