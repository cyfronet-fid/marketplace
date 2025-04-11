# frozen_string_literal: true

require "rails_helper"

RSpec.describe ObservedUserOffer, type: :model do
  describe "validations" do
    it { should validate_presence_of(:user) }

    it { should validate_presence_of(:offer) }
  end
end
