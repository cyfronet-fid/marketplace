# frozen_string_literal: true

require "colorize"

module Ams
  module Logger
    module_function

    def info(message)
      Rails.logger.info("[AMS] #{message}".cyan)
    end

    def warn(message)
      Rails.logger.warn("[AMS] #{message}".cyan)
    end

    def error(message)
      Rails.logger.error("[AMS] #{message}".cyan)
    end
  end
end
