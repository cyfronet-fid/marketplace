# frozen_string_literal: true

class Bundle < ApplicationRecord
  include Offerable

  # include Offer::Parameters

  searchkick word_middle: %i[offer_name description], highlight: %i[offer_name description]

  STATUSES = { published: "published", draft: "draft", deleted: "deleted" }.freeze

  enum status: STATUSES

  belongs_to :service, optional: false
  belongs_to :main_offer, class_name: "Offer", optional: false
  belongs_to :resource_organisation, class_name: "Provider", optional: false
  has_many :bundle_offers
  has_many :offers, through: :bundle_offers, dependent: :destroy

  has_many :bundle_target_users
  has_many :target_users, through: :bundle_target_users
  has_many :bundle_vocabularies
  has_many :research_steps, through: :bundle_vocabularies, source: :vocabulary, source_type: "Vocabulary::ResearchStep"
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
  validates :research_steps, presence: true, length: { minimum: 1, message: "are required. Please add at least one" }
  validates :order_type, presence: true
  validates :main_offer, presence: true
  validate :main_offer_not_bundled
  validates :offers, presence: true, length: { minimum: 1, message: "are required. Please add at least one" }
  validates :related_training_url, mp_url: true, if: :related_training?
  validates :helpdesk_url, mp_url: true, presence: true

  def set_iid
    self.iid = bundles_count + 1 if iid.blank?
  end

  def to_param
    iid.to_s
  end

  def main_offer_not_bundled
    unless main_offer && (main_offer.bundles.size.zero? || main_offer.bundles.first == self)
      errors.add(:main_offer, "Currently you cannot connect" + " the same main offer to bundle twice.")
    end
  end

  def all_offers
    [main_offer] + offers
  end

  def bundles_count
    (service && service.bundles.maximum(:iid).to_i) || 0
  end
end
