# frozen_string_literal: true

require "rails_helper"

RSpec.describe VariantOperation, :backend do
  before do
    stub_const(
      "FakeStandalone",
      Class.new(ApplicationService) do
        def initialize(value)
          super()
          @value = value
        end

        def call
          [:standalone, @value]
        end
      end
    )
    stub_const("FakeCascading", Class.new(FakeStandalone) { def call = [:cascading, @value] })
    stub_const(
      "FakeOperation",
      Class.new do
        extend VariantOperation

        implementations marketplace: "FakeStandalone", default: "FakeCascading"
      end
    )
  end

  context "when the variant has its own implementation" do
    subject(:result) { FakeOperation.call(1) }

    before { allow(Mp::Variant).to receive(:current).and_return(:marketplace) }

    it "uses that implementation" do
      expect(result).to eq([:standalone, 1])
    end
  end

  context "when the variant has no implementation of its own" do
    subject(:result) { FakeOperation.call(1) }

    before { allow(Mp::Variant).to receive(:current).and_return(:pl) }

    it "uses the default implementation" do
      expect(result).to eq([:cascading, 1])
    end
  end

  context "when building an instance" do
    subject(:instance) { FakeOperation.new(2) }

    before { allow(Mp::Variant).to receive(:current).and_return(:whitelabel) }

    it "builds the selected implementation" do
      expect(instance).to be_a(FakeCascading)
    end
  end
end
