# frozen_string_literal: true

class Datasource::Publish < ApplicationService
  def initialize(datasource, verified: true)
    super()
    @datasource = datasource
    @status = verified ? :published : :unverified
  end

  def call
    @datasource.status = @status
    @datasource.save(validate: false)
  end
end
