# frozen_string_literal: true

require "rails_helper"

RSpec.describe Importers::Request, backend: true do
  let(:request) { double("Importers::Request") }
  let(:test_url) { "https://localhost/api" }

  def stub_provider_request(url, suffix, id: nil)
    allow_any_instance_of(Importers::Request).to receive(:call).with(url, suffix, id).and_return(
      id.blank? ? create(:eosc_registry_providers_response) : create(:eosc_registry_provider_response, eid: id)
    )
  end

  def stub_services_response(url, suffix)
    allow_any_instance_of(Importers::Request).to receive(:call).with(url, suffix).and_return(
      create(:eosc_registry_services_response)
    )
  end

  def stub_error_response(url, suffix)
    allow_any_instance_of(Importers::Request).to receive(:call).with(url, suffix).and_return(Errno::ECONNREFUSED)
  end
end
