# frozen_string_literal: true

class OMS::Authorization::Basic < OMS::Authorization
  validates :user, presence: true
  validates :password, presence: true
end
