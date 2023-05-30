# frozen_string_literal: true

class Service::Ess::Add < ApplicationService
  def initialize(service, async: true, dry_run: false)
    super()
    @service = service
    @type = service.type == "Datasource" ? "data source" : "service"
    @async = async
    @dry_run = dry_run
  end

  def call
    @service.offers.each(&:save) unless @service.offers.published.size.zero?
    @async ? Ess::UpdateJob.perform_later(payload) : Ess::Update.call(payload)
  end

  private

  def payload
    { action: "update", data_type: @type, data: Ess::ServiceSerializer.new(@service).as_json }.as_json
  end
end
