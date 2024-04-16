# frozen_string_literal: true

require 'iso-639'

class Raid::Language
  class << self
    def all
      ISO_639::ISO_639_2
    end
  end
end
