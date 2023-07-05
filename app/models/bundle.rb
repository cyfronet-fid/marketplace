# frozen_string_literal: true

class Bundle < ApplicationRecord
  include Offerable

  # include Offer::Parameters

  searchkick word_middle: %i[offer_name description], highlight: %i[offer_name description]

  STATUSES = { published: "published", draft: "draft", deleted: "deleted" }.freeze

  counter_culture :service,
                  column_name: proc { |model| model.published? ? "bundles_count" : nil },
                  column_names: {
                    ["bundles.status = ?", "published"] => "bundles_count"
                  }

  enum status: STATUSES

  belongs_to :service, optional: false
  belongs_to :main_offer, class_name: "Offer", optional: false
  belongs_to :resource_organisation, class_name: "Provider", optional: false
  has_many :bundle_offers
  has_many :offers, through: :bundle_offers, dependent: :destroy
  has_many :project_items

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
  validates :offers, presence: true, length: { minimum: 1, message: "are required. Please add at least one" }
  validate :offers_correct
  validates :related_training_url, mp_url: true, if: :related_training?
  validates :helpdesk_url, mp_url: true, presence: true

  after_commit :propagate_to_ess
  def set_iid
    self.iid = (service.bundles.maximum(:iid) || 0) + 1 if iid.blank?
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

  def propagate_to_ess
    status == "published" && !destroyed? ? Bundle::Ess::Add.call(self) : Bundle::Ess::Delete.call(id)
  end

  def internal
    true
  end

  def active?
    all_offers.select { |o| (o.limited && o.available_count.zero?) }.empty?
  end

  private

  def offers_correct
    errors.add(:offers, "cannot bundle self") if offers.include?(main_offer)
    errors.add(:offers, "all bundled offers must be published") unless offers.all?(&:published?)
    errors.add(:offers, "all bundled offer's services must be public") unless offers.map(&:service).all?(&:public?)
  end
end
