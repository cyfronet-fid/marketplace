# frozen_string_literal: true

MP_VERSION = ENV["MP_VERSION"] || File.read(Rails.root.join("VERSION")).strip

# time after which user can rate service that starts when service become ready
# default value is set to 90 days, ENV variable should represent number of days
RATE_AFTER_PERIOD = ENV["RATE_AFTER_PERIOD"].present? ? (ENV["RATE_AFTER_PERIOD"]).to_i.days : 90.days
