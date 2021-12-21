# frozen_string_literal: true

module FormatsHelper
  def to_js_date_format(date_format)
    date_format.gsub("%Y", "yyyy").gsub("%m", "mm").gsub("%d", "dd")
  end
end
