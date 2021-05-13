# frozen_string_literal: true

class Importers::Vocabulary
  include Importable

  def initialize(data, type, token = nil)
    @data = data
    @token = token
    @type = type
  end

  def call
    {
      eid: @data["id"],
      name: @data["name"],
      description: @data["description"],
      parent: @data["parentId"].present? ? @type.find_by(eid: @data["parentId"]) : nil
    }
  end
end
