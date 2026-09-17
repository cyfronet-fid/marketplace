# frozen_string_literal: true

require "rails_helper"

RSpec.describe Bundle::Delete, :backend do
  let(:bundle) { create(:bundle) }

  before { described_class.call(bundle) }

  it "destroys a bundle without project items" do
    expect(Bundle).not_to exist(bundle.id)
  end
end
