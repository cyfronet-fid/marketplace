# frozen_string_literal: true

class DeployableService::Update < DeployableService::ApplicationService
  def initialize(deployable_service, params, logo = nil)
    super(deployable_service)
    @params = params
    @logo = logo
  end

  def call
    ActiveRecord::Base.transaction do
      @deployable_service.update_logo!(@logo) if @logo
      @deployable_service.update!(@params)
    end

    true
  rescue ActiveRecord::RecordInvalid
    false
  end
end
