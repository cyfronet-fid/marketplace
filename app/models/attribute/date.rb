# frozen_string_literal: true

require "json-schema"

class Attribute::Date < Attribute
  def value_type_schema
    { type: "string", enum: ["string"] }
  end

  def value_schema
    { type: "string", format: "date", minLength: 1 }
  end

  def value_from_param(param)
    @value = param
  end

  def value_validity
    super

    errors.add(:id, "Please select date after #{I18n.l(min_date - 1.day)}") if before_min?
    errors.add(:id, "Please select date before #{I18n.l(max_date + 1.day)}") if after_max?
  end

  def date_format
    I18n.t("date.formats.default")
  end

  TYPE = "date"

  private

  def before_min?
    min_date && value_date < min_date
  end

  def after_max?
    max_date && value_date > max_date
  end

  def min_date
    @min_date ||= parse_date(config&.[]("min"))
  end

  def max_date
    @max_date ||= parse_date(config&.[]("max"))
  end

  def value_date
    @value_date ||= parse_date(value)
  end

  def parse_date(date_str)
    case date_str
    when "now"
      ::Date.today
    when nil
      nil
    else
      ::Date.strptime(date_str, date_format)
    end
  end
end
