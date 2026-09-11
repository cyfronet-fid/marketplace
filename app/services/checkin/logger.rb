# frozen_string_literal: true

module Checkin
  module Logger
    module_function

    def info(message)
      Rails.logger.info("\e[42m[Checkin] #{message}\e[0m")
    end

    def warn(message)
      Rails.logger.warn("\e[42m[Checkin] #{message}\e[0m")
    end

    def error(message)
      Rails.logger.error("\e[42m[Checkin] #{message}\e[0m")
    end
  end
end
