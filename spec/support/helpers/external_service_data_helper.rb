# frozen_string_literal: true

module ExternalServiceDataHelper
  def stub_external_data
    creds = double(Google::Auth::ServiceAccountCredentials.new)
    allow_any_instance_of(Google::Analytics).to receive(:login).and_return(creds)
    allow_any_instance_of(Google::Auth::ServiceAccountCredentials).to receive(:fetch_access_token!).and_return(creds)
    allow_any_instance_of(Analytics::PageViewsAndRedirects).to receive(:call).and_return(
      { views: "115", redirects: "25" }
    )
    allow_any_instance_of(ServicesController).to receive(:fetch_status).and_return("OK")
  end
end
