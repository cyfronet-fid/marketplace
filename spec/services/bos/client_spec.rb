# frozen_string_literal: true

require "rails_helper"

RSpec.describe Bos::Client, :backend do
  subject(:client) { described_class.new }

  let(:project_item) { create(:project_item) }
  let(:orders_url) { "https://bos.example.com/api/orders" }

  before do
    allow(Rails.configuration).to receive_messages(
      bos_enabled: enabled,
      bos_base_url: "https://bos.example.com",
      bos_api_key: "key"
    )
    stub_request(:post, orders_url).to_return(status: 200, body: "{}",
                                              headers: { "Content-Type" => "application/json" })
    client.create_order(project_item)
  end

  context "when BOS is disabled" do
    let(:enabled) { false }

    it "does not call BOS" do
      expect(a_request(:post, orders_url)).not_to have_been_made
    end
  end

  context "when BOS is enabled" do
    let(:enabled) { true }

    it "posts the order with the project item reference" do
      expect(
        a_request(:post, orders_url).with(
          body: hash_including("external_ref" => project_item.iid.to_s, "owner_email" => project_item.user.email),
          headers: { "x-key" => "key" }
        )
      ).to have_been_made
    end
  end
end
