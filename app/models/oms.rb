# frozen_string_literal: true

class Oms < ApplicationRecord
  has_many :oms_administrations, dependent: :destroy
  has_many :administrators,
           through: :oms_administrations,
           source: :user,
           class_name: "User"
  has_many :oms_providers, dependent: :destroy
  has_many :providers, through: :oms_providers
  has_many :offers, foreign_key: :primary_oms_id, dependent: :nullify
  belongs_to :service, optional: true

  self.inheritance_column = nil
  enum type: {
    global: "global",
    provider_group: "provider_group",
    resource_dedicated: "resource_dedicated"
  }

  validates :name, presence: true, uniqueness: true
  validates :type, presence: true, inclusion: { in: types }

  validates_associated :service, if: :resource_dedicated?
  validates :service, presence: true, if: :resource_dedicated?
  validates :providers, absence: true, if: :resource_dedicated?

  validates_associated :providers, if: :provider_group?
  validates :service, absence: true, if: :provider_group?
  validates :providers, presence: true, if: :provider_group?

  validates :service, absence: true, if: :global?
  validates :providers, absence: true, if: :global?

  validate :single_default_oms?, if: :default?

  validate :validate_custom_params, if: :custom_params?

  def mandatory_defaults
    custom_params&.filter { |_, v| v["mandatory"] }&.transform_values { |v| v["default"] }
  end

  def associated_projects
    # TODO: implement OMS project association - in authorization task #1883
    Project.all
  end

  def associated_events
    # TODO: implement OMS project association - in authorization task #1883
    Event.all
  end

  private
    def single_default_oms?
      if Oms.where.not(name: name).pluck(:default).any?
        errors.add(:default, "there can't be more than one default OMS")
      end
    end

    def validate_custom_params
      unless custom_params.values.all? { |param| JSON::Validator.validate(CUSTOM_PARAMS_SCHEMA, param) }
        errors.add(:custom_params, "custom_params values must be either {mandatory: false}, or {mandatory: true, default: 'value'}")
      end
    end

    CUSTOM_PARAMS_SCHEMA = {
      type: "object",
      oneOf: [
        {
          properties: {
            mandatory: { type: "boolean", enum: [true] },
            default: { type: "string" }
          },
          additionalProperties: false,
          required: [:mandatory, :default]
        },
        {
          properties: {
            mandatory: { type: "boolean", enum: [false] }
          },
          additionalProperties: false,
          required: [:mandatory]
        }
      ]
  }
end
