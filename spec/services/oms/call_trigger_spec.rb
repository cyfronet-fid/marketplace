# frozen_string_literal: true

require "rails_helper"

RSpec.describe OMS::CallTrigger do
  it "doesn't execute if trigger_url.blank?" do
    allow(Unirest).to receive(:post)

    described_class.new(build(:oms, trigger_url: "")).call

    expect(Unirest).not_to have_received(:post)
  end

  it "executes if trigger_url.present?" do
    trigger_url = "url_value"
    allow(Unirest).to receive(:post)

    described_class.new(build(:oms, trigger_url: trigger_url)).call

    expect(Unirest).to have_received(:post).with(trigger_url)
  end
end
