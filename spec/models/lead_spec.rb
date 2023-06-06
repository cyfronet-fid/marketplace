# frozen_string_literal: true

require "rails_helper"

RSpec.describe Lead, type: :model, backend: true do
  subject { create(:lead) }

  it { should validate_presence_of(:header) }
  it { should validate_presence_of(:url) }
  it { should validate_presence_of(:body) }
  it { should delegate_method(:template).to(:lead_section) }

  it "should have picture" do
    lead = create(:lead)
    expect(lead.picture).to be_an_instance_of(ActiveStorage::Attached::One)
  end

  it "should belongs to lead_section" do
    lead_section = create(:lead_section)
    lead = create(:lead, lead_section: lead_section)

    expect(lead.lead_section).to eq(lead_section)
  end
end
