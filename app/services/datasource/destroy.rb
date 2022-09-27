# frozen_string_literal: true

class Datasource::Destroy
  def initialize(datasource)
    @datasource = datasource
  end

  def call
    @datasource.destroy
  end
end
