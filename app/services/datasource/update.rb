# frozen_string_literal: true

class Datasource::Update < ApplicationService
  def initialize(datasource, params, logo = nil)
    super()
    @datasource = datasource
    @params = params
    @logo = logo
  end

  def call
    ActiveRecord::Base.transaction do
      if @datasource.public_contacts.present? && @datasource.public_contacts.all?(&:marked_for_destruction?)
        @datasource.public_contacts[0].reload
      end
      @params.merge(status: :unverified) if @datasource.errored? && @datasource.valid?

      @datasource.update_logo!(@logo) if @logo
      @datasource.update!(@params)
    end
    true
  rescue ActiveRecord::RecordInvalid
    false
  end
end
