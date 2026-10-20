# frozen_string_literal: true

require "rails_helper"

RSpec.describe Datasource::PcDelete, :backend do
  let(:datasource) { create(:datasource) }

  before do
    create(:service_source, source_type: :eosc_registry, service: datasource, eid: datasource.id)
    described_class.new(datasource.id).call
  end

  it "turns the datasource back into a service" do
    expect(Service.find(datasource.id).type).to eq("Service")
  end
end
