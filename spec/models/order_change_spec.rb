# frozen_string_literal: true

require "rails_helper"

RSpec.describe OrderChange, type: :model do
  it { should belong_to(:order) }
end
