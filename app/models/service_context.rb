# frozen_string_literal: true

class ServiceContext
  attr_reader :service, :from_backoffice, :status

  def initialize(service, from_backoffice)
    @service = service
    @status = service.status
    @from_backoffice = from_backoffice
  end
end
