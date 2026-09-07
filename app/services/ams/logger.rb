# frozen_string_literal: true

module Ams
  module Logger
    module_function

    def info(message)
      Rails.logger.info("[AMS] #{message}")
    end

    def warn(message)
      Rails.logger.warn("[AMS] #{message}")
    end

    def error(message)
      Rails.logger.error("[AMS] #{message}")
    end
  end
end
