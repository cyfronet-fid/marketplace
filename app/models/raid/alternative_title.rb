# frozen_string_literal: true

class Raid::AlternativeTitle < Raid::Title
  after_initialize :set_type

  def set_type
    self.title_type = "alternative"
  end
end
