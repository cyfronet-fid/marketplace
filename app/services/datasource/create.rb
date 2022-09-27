# frozen_string_literal: true

class Datasource::Create < ApplicationService
  def initialize(datasource, logo = nil)
    super()
    @datasource = datasource
    @logo = logo
  end

  def call
    @datasource.update_logo!(@logo) if @logo && @service.logo.blank?
    @datasource.save

    @datasource
  end
end
