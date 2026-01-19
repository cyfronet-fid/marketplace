# frozen_string_literal: true

class Offer < ApplicationRecord
  # TODO: validate parameter ids uniqueness - for now we are safe thanks to schema validation though
  include ActionView::Helpers::TextHelper
  include Offerable
  include Offer::Parameters
  include Propagable
  include Statusable

  acts_as_taggable

  searchkick word_middle: %i[offer_name description], highlight: %i[offer_name description]

  def search_data
    { offer_name: name, description: description, service_id: resource_id, order_type: order_type }
  end

  # Returns the resource ID (service or deployable_service) for API compatibility
  def resource_id
    orderable_id
  end

  def should_index?
    status == "published" && offers_count > 1
  end

  scope :bundle_exclusive, -> { where(bundle_exclusive: true, status: :published) }

  # =============================================================================
  # Polymorphic orderable join scopes
  # These provide reusable joins for querying through the polymorphic orderable
  # association. Use these instead of writing raw SQL joins in other files.
  # =============================================================================

  # INNER JOIN to services table only (excludes DeployableService offers)
  scope :join_service, -> { joins(JOIN_SERVICE_SQL) }

  # LEFT JOIN to both services and deployable_services tables (includes all offer types)
  scope :join_orderable, -> { joins(LEFT_JOIN_SERVICE_SQL).joins(LEFT_JOIN_DEPLOYABLE_SERVICE_SQL) }

  # Filter to only offers with published orderable (works with join_orderable)
  scope :with_published_orderable,
        -> do
          where(
            "(offers.orderable_type = 'Service' AND services.status IN (?)) " \
              "OR (offers.orderable_type = 'DeployableService' AND deployable_services.status IN (?))",
            Statusable::PUBLIC_STATUSES,
            Statusable::PUBLIC_STATUSES
          )
        end

  # SQL fragments for joins (exposed as constants for use in other classes)
  JOIN_SERVICE_SQL =
    "INNER JOIN services ON services.id = offers.orderable_id " \
      "AND offers.orderable_type = 'Service'"
  LEFT_JOIN_SERVICE_SQL =
    "LEFT JOIN services ON services.id = offers.orderable_id " \
      "AND offers.orderable_type = 'Service'"
  LEFT_JOIN_DEPLOYABLE_SERVICE_SQL =
    "LEFT JOIN deployable_services ON deployable_services.id = offers.orderable_id " \
      "AND offers.orderable_type = 'DeployableService'"

  # =============================================================================
  # Business logic scopes (use the join scopes above)
  # =============================================================================

  scope :inclusive, -> { where(bundle_exclusive: false, status: :published).join_orderable.with_published_orderable }

  scope :active,
        -> do
          where(
            "offers.status = ? AND bundle_exclusive = ? AND (limited_availability = ? OR availability_count > ?)",
            :published,
            false,
            false,
            0
          )
        end

  scope :accessible, -> { where(status: :published).join_orderable.with_published_orderable }

  scope :manageable, -> { where(status: Statusable::MANAGEABLE_STATUSES) }

  # Counter cache for offers_count on Service only (DeployableService doesn't have this column)
  # counter_culture supports polymorphic associations of one level
  # Returns nil for DeployableService to skip the update
  counter_culture :orderable,
                  column_name:
                    proc { |model| model.published? && model.orderable_type == "Service" ? "offers_count" : nil },
                  column_names: {
                    ["offers.status = ? AND offers.orderable_type = ?", "published", "Service"] => "offers_count"
                  }

  # Polymorphic association for orderable resource (Service or DeployableService)
  belongs_to :orderable, polymorphic: true

  # Convenience methods for accessing orderable as Service or DeployableService
  # These provide API compatibility after removing legacy columns
  def service
    orderable if orderable_type == "Service"
  end

  def service=(value)
    self.orderable = value
  end

  def deployable_service
    orderable if orderable_type == "DeployableService"
  end

  def deployable_service=(value)
    self.orderable = value
  end

  # ID accessor methods for backward compatibility
  def service_id
    orderable_id if orderable_type == "Service"
  end

  def deployable_service_id
    orderable_id if orderable_type == "DeployableService"
  end

  belongs_to :primary_oms, class_name: "OMS", optional: true
  has_many :project_items, dependent: :restrict_with_error

  # Return the parent service (either Service or DeployableService)
  # Now uses the polymorphic orderable association
  def parent_service
    orderable
  end

  before_validation :set_internal
  before_validation :set_oms_details
  before_validation :sanitize_oms_params
  before_validation :set_iid, on: :create
  before_create :set_iid, if: -> { iid.blank? }

  has_many :bundle_offers
  has_many :bundles, through: :bundle_offers, dependent: :destroy
  has_many :main_bundles, class_name: "Bundle", foreign_key: "main_offer_id", dependent: :restrict_with_error
  has_many :offer_vocabularies
  has_many :observed_user_offers, dependent: :destroy
  has_many :users, through: :observed_user_offers
  belongs_to :offer_category, class_name: "Vocabulary::ServiceCategory"
  belongs_to :offer_type, class_name: "Vocabulary::ServiceCategory", optional: true
  belongs_to :offer_subtype, class_name: "Vocabulary::ServiceCategory", optional: true

  validates :iid, presence: true, numericality: true
  validate :service_or_deployable_service_present
  validates :order_url, mp_url: true, if: :order_url?
  validates :availability_count,
            numericality: {
              greater_than_or_equal_to: 0,
              message: "Quantity must be greater than or equal to 0"
            }

  validate :primary_oms_exists?, if: -> { primary_oms_id.present? }
  validate :check_main_bundles, if: -> { draft? }

  with_options unless: :draft? do
    validate :proper_oms?, if: -> { primary_oms.present? }
    validates :oms_params, absence: true, if: -> { current_oms.blank? }
    validate :check_oms_params, if: -> { current_oms.present? }
    validate :same_order_type_as_in_service, if: -> { service&.order_type.present? }
  end

  before_destroy :check_main_bundles

  def current_oms
    primary_oms || OMS.find_by(default: true)
  end

  def to_param
    iid.to_s
  end

  def bundle?
    main_bundles.published.size.positive?
  end

  def bundled?
    bundles.published.size.positive?
  end

  def slug_iid
    # Works with both Service and DeployableService via polymorphic orderable
    "#{parent_service&.slug}/#{iid}"
  end

  def self.find_by_slug_iid!(slug_iid)
    raise ArgumentError, "must be a string" unless slug_iid.is_a?(String)
    split = slug_iid.split("/")
    raise ArgumentError, "must have the two components separated with a forward slash '/'" if split.length != 2
    Offer.find_by!(orderable: Service.find_by!(slug: split[0]), iid: split[1].to_i)
  end

  private

  def set_iid
    # Use orderable (polymorphic) to work with both Service and DeployableService
    self.iid = (orderable&.offers&.maximum(:iid) || 0) + 1 if iid.blank?
  end

  def duplicates?(list)
    list.uniq.size != list.size
  end

  def offers_count
    # Use parent_service to work with both Service and DeployableService
    parent_service&.offers_count || 0
  end

  def oms_params_match?
    unless (Set.new(oms_params.keys) - Set.new(current_oms.custom_params.keys)).empty?
      errors.add(:oms_params, "additional unspecified keys added")
      return false
    end

    missing_keys = Set.new(current_oms.custom_params.keys) - Set.new(oms_params.keys)
    if missing_keys.intersect?(Set.new(current_oms.mandatory_defaults.keys))
      errors.add(:oms_params, "missing mandatory keys")
    end
  end

  def same_order_type_as_in_service
    return unless parent_service # Skip validation if no parent service

    other_services = parent_service.offers.published.reject { |o| o&.id == id }
    other_check = other_services.none? { |o| o.order_type == parent_service&.order_type }
    if (other_services.empty? || other_check) && order_type != parent_service.order_type
      errors.add(:order_type, "must be the same as in the service: #{parent_service.order_type}")
    end
  end

  def check_main_bundles
    unless main_bundles.empty?
      errors.add(
        :base,
        "Offer is connected as main offer to #{pluralize(main_bundles.size, "bundle")}: " +
          "#{main_bundles.map(&:name).join(", ")}. Firstly change main offer or delete mentioned bundles"
      )
    end
  end

  def check_oms_params
    if current_oms.custom_params.present?
      if current_oms.mandatory_defaults.present?
        oms_params.blank? ? errors.add(:oms_params, "can't be blank") : oms_params_match?
      end
    elsif oms_params.present?
      errors.add(:oms_params, "must be blank if primary OMS' custom params are blank")
    end
  end

  def primary_oms_exists?
    errors.add(:primary_oms, "doesn't exist") unless OMS.find_by_id(primary_oms_id).present?
  end

  def proper_oms?
    # Only validate OMS for Service offers (DeployableService doesn't have available_omses)
    return true unless service.present?

    service.available_omses.include?(primary_oms) ||
      errors.add(:primary_oms, "has to be available in the service scope").nil?
  end

  def set_internal
    self.internal = false unless order_required?
  end

  def set_oms_details
    unless internal?
      self.primary_oms = nil
      self.oms_params = nil
    end
  end

  def sanitize_oms_params
    oms_params.select! { |_, v| v.present? } if oms_params.present?
  end

  def service_or_deployable_service_present
    errors.add(:base, "Must belong to either service or deployable service") if orderable.blank?
  end
end
