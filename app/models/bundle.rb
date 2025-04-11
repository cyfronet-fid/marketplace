# frozen_string_literal: true

class Bundle < ApplicationRecord
  include Offerable
  include Propagable
  include Statusable
  include Viewable

  # include Offer::Parameters

  acts_as_taggable

  searchkick word_middle: %i[offer_name description], highlight: %i[offer_name description]

  counter_culture :service,
                  column_name: proc { |model| model.published? ? "bundles_count" : nil },
                  column_names: {
                    ["bundles.status = ?", "published"] => "bundles_count"
                  }

  before_save :clear_training

  belongs_to :service, optional: false
  belongs_to :main_offer, class_name: "Offer", optional: false
  belongs_to :resource_organisation, class_name: "Provider", optional: false
  has_many :bundle_offers
  has_many :offers, through: :bundle_offers, dependent: :destroy, validate: false
  has_many :project_items

  has_many :bundle_target_users
  has_many :target_users, through: :bundle_target_users
  has_many :bundle_vocabularies
  has_many :research_activities,
           through: :bundle_vocabularies,
           source: :vocabulary,
           source_type: "Vocabulary::ResearchActivity"
  has_many :bundle_goals, through: :bundle_vocabularies, source: :vocabulary, source_type: "Vocabulary::BundleGoal"
  has_many :capabilities_of_goals,
           through: :bundle_vocabularies,
           source: :vocabulary,
           source_type: "Vocabulary::BundleCapabilityOfGoal"
  has_many :bundle_categories
  has_many :categories, through: :bundle_categories
  has_many :bundle_scientific_domains
  has_many :scientific_domains, through: :bundle_scientific_domains

  validate :set_iid, on: :create
  validate :offers_correct, :main_offer_published
  validates :name, presence: true
  validates :description, presence: true
  validates :bundle_goals, presence: true, length: { minimum: 1, message: "are required. Please add at least one" }
  validates :capabilities_of_goals,
            presence: true,
            length: {
              minimum: 1,
              message: "are required. Please add at least one"
            }
  validates :target_users, presence: true, length: { minimum: 1, message: "are required. Please add at least one" }
  validates :scientific_domains,
            presence: true,
            length: {
              minimum: 1,
              message: "are required. Please add at least one"
            }
  validates :research_activities,
            presence: true,
            length: {
              minimum: 1,
              message: "are required. Please add at least one"
            }
  validates :order_type, presence: true
  validates :main_offer, presence: true
  unless draft
    validates :offers, presence: true, length: { minimum: 1, message: "are required. Please add at least one" }
  end
  validate :offers_correct
  validates :related_training_url, mp_url: true, if: :related_training?
  validates :helpdesk_url, mp_url: true, presence: true

  def set_iid
    self.iid = (service.bundles.maximum(:iid) || 0) + 1 if iid.blank?
  end

  def offers=(value)
    super(value.uniq)
  end

  def to_param
    iid.to_s
  end

  def all_offers
    [main_offer] + offers
  end

  def bundles_count
    service&.bundles&.size || 0
  end

  def internal
    true
  end

  def limited_availability
    false
  end

  def active?
    all_offers.none? { |o| o.limited_availability && o.availability_count.zero? }
  end

  private

  def clear_training
    self.related_training_url = "" unless related_training
  end

  def offers_correct
    if offers.includes(:service).present?
      errors.add(:offers, "cannot bundle main offer") if offers.include?(main_offer)
      errors.add(:offers, "must have only published offers selected") unless offers.all?(&:published?)
      errors.add(:offers, "must have offers with public services selected") unless offers.map(&:service).all?(&:public?)
    end
  end

  def main_offer_published
    errors.add(:main_offer, "must be published") if published? && main_offer && !main_offer&.published?
  end
end
