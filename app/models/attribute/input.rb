# frozen_string_literal: true

require "json-schema"

class Attribute::Input < Attribute
  # validate :id, presence: true
  # validate :label, presence: true

  protected
    TYPE = "input"
end
