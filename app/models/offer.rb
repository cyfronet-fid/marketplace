# frozen_string_literal: true

class Offer < ApplicationRecord
  # TODO: validate parameter ids uniqueness - for now we are safe thanks to schema validation though
  include Offerable
  include Offer::Parameters

  searchkick word_middle: [:offer_name, :description],
            highlight: [:offer_name, :description]

  STATUSES = {
    published: "published",
    draft: "draft",
    deleted: "deleted"
  }

  def search_data
    {
      offer_name: name,
      description: description,
      service_id: service_id,
      order_type: order_type
    }
  end

  def should_index?
    status == STATUSES[:published] && offers_count > 1
  end

  counter_culture :service, column_name: proc { |model| model.published? ? "offers_count" : nil },
                  column_names: {
                    ["offers.status = ?", "published"] => "offers_count"
                  }

  enum status: STATUSES

  belongs_to :service
  belongs_to :primary_oms, class_name: "Oms", optional: true
  has_many :project_items,
           dependent: :restrict_with_error

  validate :set_iid, on: :create
  validates :service, presence: true
  validates :iid, presence: true, numericality: true
  validates :status, presence: true

  validate :primary_oms_exists?, if: -> { primary_oms_id.present? }
  validate :proper_oms?, if: -> { primary_oms.present? }
  validates :oms_params, absence: true, if: -> { current_oms.blank? }
  validate :check_oms_params, if: -> { current_oms.present? }

  def current_oms
    primary_oms || Oms.find_by(default: true)
  end

  def to_param
    iid.to_s
  end

  private
    def set_iid
      self.iid = offers_count + 1 if iid.blank?
    end

    def offers_count
      service && service.offers.maximum(:iid).to_i || 0
    end

    def oms_params_match?
      if (Set.new(oms_params.keys) - Set.new(current_oms.custom_params.keys)).length > 0
        errors.add(:oms_params, "additional unspecified keys added")
        return
      end

      missing_keys = Set.new(current_oms.custom_params.keys) - Set.new(oms_params.keys)
      if (missing_keys & Set.new(current_oms.mandatory_defaults.keys)).length > 0
        errors.add(:oms_params, "missing mandatory keys")
      end
    end

    def check_oms_params
      if current_oms.custom_params.present?
        if current_oms.mandatory_defaults.present?
          oms_params.blank? ? errors.add(:oms_params, "can't be blank") : oms_params_match?
        end
      else
        errors.add(:oms_params, "must be blank if primary oms' custom params are blank") if oms_params.present?
      end
    end

    def primary_oms_exists?
      unless Oms.find_by_id(primary_oms_id).present?
        errors.add(:primary_oms, "doesn't exist")
      end
    end

    def proper_oms?
      unless service.available_oms.include? primary_oms
        errors.add(:primary_oms, "has to be available in the resource scope")
      end
    end
end
