# frozen_string_literal: true

class Importers::Datasource < ApplicationService
  include Importable

  def initialize(data)
    super()
    @data = data
  end

  def call
    {
      version_control: @data["versionControl"] == true,
      datasource_classification: map_datasource_classification(@data["datasourceClassification"]),
      research_product_types: Array(@data["researchProductTypes"]),
      thematic: @data["thematic"] == true
    }
  end
end
