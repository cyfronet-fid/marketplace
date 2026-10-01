# frozen_string_literal: true

class Catalogue::AlternativeIdentifierSerializer < ApplicationSerializer
  attribute :identifier_type, key: :type
  attribute :value
end
