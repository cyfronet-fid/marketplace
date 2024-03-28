# frozen_string_literal: true

require "languages"

class Raid::Language
  class << self
    def living
      Languages.living.sort_by(&:name)
    end
  end
end
