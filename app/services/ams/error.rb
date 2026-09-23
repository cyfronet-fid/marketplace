# frozen_string_literal: true

module Ams
  class Error < StandardError
    def initialize(message)
      super("[AMS] #{message}")
    end
  end
end
