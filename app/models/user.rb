# frozen_string_literal: true

class User < ApplicationRecord
  acts_as_token_authenticatable

  devise :database_authenticatable, :rememberable, :trackable,
         :omniauthable, omniauth_providers: %i[checkin]

  include RoleModel
  roles :admin, :service_portfolio_manager, :executive

  has_many :projects, dependent: :destroy

  has_many :service_user_relationships, dependent: :destroy
  has_many :owned_services,
           through: :service_user_relationships,
           source: :service,
           class_name: "Service"
  has_many :user_categories, dependent: :destroy
  has_many :categories, through: :user_categories
  has_many :user_scientific_domains, dependent: :destroy
  has_many :scientific_domains, through: :user_scientific_domains

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

  def data_administrator?
    DataAdministrator.where(email: email).count.positive?
  end

  def managed_services
    Service.administered_by(self)
  end

  def to_s
    full_name
  end

  def valid_token?
    authentication_token != "revoked" && authentication_token.present?
  end

  def self.generate_token
    Devise.friendly_token
  end
end
