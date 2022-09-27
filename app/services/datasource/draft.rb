# frozen_string_literal: true

class Datasource::Draft < ApplicationService
  def initialize(datasource)
    super()
    @datasource = datasource
  end

  def call
    @datasource.status = :draft
    @datasource.save(validate: false)
  end
end
