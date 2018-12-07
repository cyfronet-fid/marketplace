# frozen_string_literal: true

module Backoffice::ServiceHelper
  def return_published_service(service)
    service.status = :published
    service
  end
end
