# frozen_string_literal: true

module Presentable::DetailsStyleHelper
  MONITORING_STATUS_CLASS = {
    OK: "text-success",
    WARNING: "text-warning",
    CRITICAL: "text-danger",
    UNKNOWN: "text-primary",
    MISSING: "text-info"
  }.freeze

  def details_column_width_lg(columns)
    [4, 12 / columns.length].min
  end

  def details_column_width_md(columns)
    [6, 12 / columns.length].min
  end

  def details_column_width_sm(_columns)
    12
  end

  def display_detail?(detail, service)
    (detail[:clazz].blank? && any_present?(service, *detail[:fields])) ||
      (detail[:clazz] && service.send(detail[:clazz]).present?)
  end

  def monitoring_numerable_class(number)
    case number
    when 80..200
      "text-success"
    when 50..80
      "text-warning"
    when ..50
      "text-danger"
    end
  end

  def monitoring_status_class(status)
    MONITORING_STATUS_CLASS[status.to_sym] if status
  end

  def monitoring_tooltip(status)
    t("components.presentable.sidebar_component.fields.monitoring_data_tooltip.#{status}")
  end
end
