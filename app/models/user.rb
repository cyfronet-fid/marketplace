# frozen_string_literal: true

class User < ApplicationRecord
  devise :database_authenticatable, :rememberable, :trackable,
         :omniauthable, omniauth_providers: %i[checkin]

  include RoleModel
  roles :admin, :service_portfolio_manager

  has_many :projects, dependent: :destroy

  has_many :service_user_relationships, dependent: :destroy
  has_many :owned_services,
           through: :service_user_relationships,
           source: :service,
           class_name: "Service"

  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :email, presence: true
  validates :uid, presence: true

  def full_name
    "#{first_name} #{last_name}"
  end

  def service_owner?
    owned_services_count.positive?
  end

  def to_s
    full_name
  end
end
