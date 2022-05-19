# frozen_string_literal: true

module Presentable::DetailsStyleHelper
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
end
