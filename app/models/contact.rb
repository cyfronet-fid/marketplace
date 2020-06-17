# frozen_string_literal: true

class Contact < ApplicationRecord
  belongs_to :contactable, polymorphic: true

  validates :email, presence: true, email: true
  validates :type, presence: true
end
