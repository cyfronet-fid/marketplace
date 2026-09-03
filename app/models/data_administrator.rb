# frozen_string_literal: true

class DataAdministrator < ApplicationRecord
  before_save :connect_user

  scope :catalogues, -> { joins(:catalogue).where.not(catalogues: { status: :deleted }) }
  scope :providers, -> { joins(:provider).where.not(providers: { status: :deleted }) }

  counter_culture :user,
                  column_name: proc { |model| model.joined.present? ? "#{model.joined}_count" : nil },
                  column_names: -> do
                    {
                      DataAdministrator.catalogues => :catalogues_count,
                      DataAdministrator.providers => :providers_count
                    }
                  end

  has_one :catalogue_data_administrator
  has_one :provider_data_administrator

  has_one :provider, through: :provider_data_administrator
  has_one :catalogue, through: :catalogue_data_administrator

  belongs_to :user, optional: true, inverse_of: :data_administrators

  validates :first_name, :last_name, presence: true
  validates :email, presence: true, email: true

  def connect_user
    previous_id = user_id
    user = User.find_by(email: email)
    if previous_id.present? && previous_id != user&.id
      previous_user = User.find(previous_id)
      previous_user.decrement("#{joined}_count", 1) if joined.present?
      previous_user.save
    end
    self.user_id = user.present? ? user.id : nil
  end

  def joined
    if catalogue?
      "catalogues"
    elsif provider?
      "providers"
    end
  end

  def catalogue?
    catalogue_data_administrator.present?
  end

  def provider?
    provider_data_administrator.present?
  end
end
