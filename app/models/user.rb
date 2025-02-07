# frozen_string_literal: true

class User < ApplicationRecord
  acts_as_token_authenticatable

  after_create :connect_data_administrators

  devise :database_authenticatable, :rememberable, :trackable, :omniauthable, omniauth_providers: %i[checkin]

  include Publishable
  include RoleModel
  roles :admin, :coordinator, :executive

  has_many :projects, dependent: :destroy

  has_many :user_categories, dependent: :destroy
  has_many :categories, through: :user_categories
  has_many :user_scientific_domains, dependent: :destroy
  has_many :scientific_domains, through: :user_scientific_domains
  has_many :oms_administrations, dependent: :destroy
  has_many :administrated_omses, through: :oms_administrations, source: :oms
  has_many :user_service, dependent: :destroy
  has_many :favourite_services, through: :user_service, source: :service, class_name: "Service"
  has_many :data_administrators, primary_key: :id, foreign_key: :user_id
  has_many :provider_data_administrators, through: :data_administrators
  has_many :catalogue_data_administrators, through: :data_administrators
  has_many :providers, through: :provider_data_administrators
  has_many :catalogues, through: :catalogue_data_administrators

  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :email, presence: true
  validates :uid, presence: true

  def full_name
    "#{first_name} #{last_name}"
  end

  def provider_owner?
    providers_count.positive?
  end

  def catalogue_owner?
    catalogues_count.positive?
  end

  def data_administrator?
    catalogue_owner? || provider_owner?
  end

  def default_oms_administrator?
    administrated_omses.where(default: true).present?
  end

  def to_s
    full_name
  end

  def valid_token?
    authentication_token.present?
  end

  def connect_data_administrators
    DataAdministrator.where(email: email).each(&:save)
  end
end
