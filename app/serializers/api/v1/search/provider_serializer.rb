# frozen_string_literal: true

class Api::V1::Search::ProviderSerializer < ApplicationSerializer
  attributes :name, :pid

  def pid
    object.pid || object.sources&.first&.eid
  end
end
