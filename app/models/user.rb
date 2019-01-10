# frozen_string_literal: true

class User < ApplicationRecord
  devise :database_authenticatable, :rememberable, :trackable, :validatable,
         :omniauthable, omniauth_providers: %i[checkin]

  include RoleModel
  roles :admin, :service_portfolio_manager

  has_many :projects, dependent: :destroy
  has_many :affiliations, dependent: :destroy

  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :email, presence: true
  validates :uid, presence: true

  def full_name
    "#{first_name} #{last_name}"
  end

  def active_affiliations
    affiliations.where(status: :active)
  end

  def active_affiliation?
    active_affiliations_count.positive?
  end
end
