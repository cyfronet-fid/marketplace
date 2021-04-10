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

  def project_items_for(project)
    if default?
      project.project_items
    else
      project.project_items.where(offers: { primary_oms: self }).joins(:offer).distinct
    end
  end

  def projects
    if default?
      Project.all
    else
      Project.where(project_items: { offers: { primary_oms: self } }).joins(project_items: :offer).distinct
    end
  end

  def messages
    if default?
      Message.all
    else
      # Outer join Message with ProjectItem OR Project messageables - and look for oms inside their respective offers.primary_oms
      Message.where("offers.primary_oms_id = ?", self)
             .or(Message.where("offers_project_items.primary_oms_id = ?", self))
             .left_outer_joins(project_item: :offer, project:  { project_items: :offer })
             .distinct
    end
  end

  def events
    if default?
      Event.all
    else
      # Outer join Event with ProjectItem OR Project OR Message eventables - and look for oms inside their respective offers.primary_oms
      Event.where("offers.primary_oms_id = ?", self)
           .or(Event.where("offers_project_items.primary_oms_id = ?", self))
           .or(Event.where("offers_project_items_2.primary_oms_id = ?", self))
           .or(Event.where("offers_project_items_3.primary_oms_id = ?", self))
           .left_outer_joins({ project_item: :offer },
                             { project: { project_items: :offer } },
                             { message: { project_item: :offer } },
                             { message: { project: { project_items: :offer } } })
           .distinct
    end
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
