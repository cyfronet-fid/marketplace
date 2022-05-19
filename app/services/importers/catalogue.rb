# frozen_string_literal: true

class Importers::Catalogue < ApplicationService
  include Importable

  def initialize(data, synchronized_at, source = "jms")
    super()
    @data = data
    @synchronized_at = synchronized_at
    @source = source
  end

  def call
    { name: @data["name"], pid: @data["id"] }
  end
end
