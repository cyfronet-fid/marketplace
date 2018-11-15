# frozen_string_literal: true

# Used to convert Postgres JSON to list of elements, which can be rendered
# in views
module FilterTechnicalParametersHelper
  EXCLUDED_TYPES = ["date"]

  def filter_technical_parameters(parameters)
    parameters.select do |parameter|
      if EXCLUDED_TYPES.include?(parameter["type"])
        false
      elsif parameter["value_type"] == "string" then
        false
      else
        true
      end
    end
  end
end
