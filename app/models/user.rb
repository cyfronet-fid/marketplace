# frozen_string_literal: true

class User < ApplicationRecord
  devise :database_authenticatable, :rememberable, :trackable, :validatable,
         :omniauthable, omniauth_providers: %i[checkin]

  include RoleModel
  roles :service_owner

  has_many :projects, dependent: :destroy
  has_many :affiliations, dependent: :destroy
  has_many :owned_services,
           class_name: "Service",
           foreign_key: "owner_id",
           dependent: :nullify

  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :email, presence: true
  validates :uid, presence: true

  def full_name
    "#{first_name} #{last_name}"
  end
end
