# frozen_string_literal: true

module ExternalServiceDataHelper
  def stub_external_data
    allow_any_instance_of(ServicesController).to receive(:fetch_status).and_return("OK")
  end
end
