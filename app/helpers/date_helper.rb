# frozen_string_literal: true

module DateHelper
  # e.g. date format: 2001-02-03T04:05:06.123456Z [optional .123456]
  def from_timestamp(date)
    unless date.match("^20\\d{2}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}(\\.{1}\\d{1,6})?Z$")
      raise ArgumentError, "invalid date"
    end
    date.to_datetime
  end
end
