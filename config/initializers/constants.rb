# frozen_string_literal: true

# time after which user can rate service that starts when service become ready
# default value is set to 90 days, ENV variable should represent number of days
RATE_AFTER_PERIOD = ENV["RATE_AFTER_PERIOD"].present? ? (ENV["RATE_AFTER_PERIOD"]).to_i.days : 90.days
