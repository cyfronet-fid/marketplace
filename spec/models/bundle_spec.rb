# frozen_string_literal: true

require "rails_helper"

RSpec.describe Bundle, type: :model do
  describe "validations" do
    subject { build(:bundle) }
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:description) }
    it { should validate_presence_of(:order_type) }
    it { should belong_to(:service).required(true) }
    it { should belong_to(:main_offer).required(true) }
    it { should belong_to(:resource_organisation).required(true) }
  end
end
