# frozen_string_literal: true

class Raid::AlternativeDescription < Raid::Description
  after_initialize :set_type

  def set_type
    self.description_type = "alternative"
  end
end
