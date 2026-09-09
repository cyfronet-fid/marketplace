# frozen_string_literal: true

module Checkin
  module Logger
    module_function

    def info(message)
      Rails.logger.info("[Checkin] #{message}")
    end

    def warn(message)
      Rails.logger.warn("[Checkin] #{message}")
    end

    def error(message)
      Rails.logger.error("[Checkin] #{message}")
    end
  end
end
