# frozen_string_literal: true

require "rails_helper"

RSpec.describe Platform, type: :model do
  describe "validations" do
    it { should validate_presence_of(:name) }

    subject { create(:platform) }
    it { should validate_uniqueness_of(:name) }
  end
end
