# frozen_string_literal: true

class Raid::MainTitle < Raid::Title
  after_initialize :set_type

  def set_type
    self.title_type = "primary"
  end
end
