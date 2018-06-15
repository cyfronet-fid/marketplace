# frozen_string_literal: true

require "rails_helper"

RSpec.describe Order do
  it { should validate_presence_of(:service) }
  it { should validate_presence_of(:user) }
  it { should validate_presence_of(:status) }

  it { should belong_to(:user) }
  it { should belong_to(:service) }

  it "creates new order in new_order state" do
    order = create(:order)

    expect(order).to be_new_order
  end
end
