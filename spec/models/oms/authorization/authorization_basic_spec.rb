# frozen_string_literal: true

require "rails_helper"

RSpec.describe OMS::Authorization::Basic, type: :model do
  it { should validate_presence_of(:user) }
  it { should validate_presence_of(:password) }
end
