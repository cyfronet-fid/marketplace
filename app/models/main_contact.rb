# frozen_string_literal: true

class MainContact < Contact
  validates :first_name, presence: true
  validates :last_name, presence: true
end
