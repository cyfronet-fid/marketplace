# frozen_string_literal: true

class User < ApplicationRecord
  devise :database_authenticatable, :rememberable, :trackable, :validatable,
         :omniauthable, omniauth_providers: %i[checkin]

  def full_name
    "#{first_name} #{last_name}"
  end
end
