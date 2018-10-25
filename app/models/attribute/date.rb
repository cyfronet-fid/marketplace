require "json-schema"

class Attribute::Date < Attribute


  def value_type_schema
    {
        "type": "string",
        "enum": ["string"]
    }
  end

  def value_schema
    {
        "type": "string",
        "format": "date",
        "minLength": 1
    }
  end

  def value_from_param(param)
    @value = param
  end

  protected

  TYPE = 'date'

end