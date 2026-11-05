# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Page head" do
  let(:scripts) { response.parsed_body.css("script").map { |script| "#{script["src"]} #{script.text}" } }

  # A Node upgraded from an older release may still set GOOGLE_ANALYTICS in production.
  before do
    allow(Rails.env).to receive(:production?).and_return(true)
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("GOOGLE_ANALYTICS").and_return("G-TEST")
    get root_path
  end

  it "loads no Google scripts" do
    expect(scripts.grep(/google|gtag/i)).to be_empty
  end
end
