# frozen_string_literal: true

class Category < ApplicationRecord
  extend FriendlyId
  friendly_id :slug_candidates, use: :slugged

  include Parentable
  include LogoAttachable
  include Publishable

  # This callback need to be defined byfore dependent: :destroy
  # relation, because in this case project_item matter. This callback need to be
  # invoked before destroying related service categories to find affected
  # services.
  before_destroy :store_affected_services

  has_one_attached :logo

  has_many :categorizations, autosave: true, dependent: :destroy
  has_many :services, through: :categorizations

  has_many :user_categories, autosave: true, dependent: :destroy
  has_many :users, through: :user_categories

  validates :name, presence: true, uniqueness: { scope: :ancestry }
  validates :logo, blob: { content_type: :image }
  validate :logo_variable, on: %i[create update]

  after_destroy :update_main_categories!

  def to_s
    name
  end

  def slug_candidates
    [:name, %i[parent_name name], %i[parent_slug name]]
  end

  def parent_name
    parent&.name || nil
  end

  def parent_slug
    parent&.slug || nil
  end

  private

  def store_affected_services
    # neet do store results in array since relation is lazy evaluated
    @main_services = Service.joins(:categorizations).where(categorizations: { category: self, main: true }).to_a
  end

  def update_main_categories!
    @main_services.each(&:set_first_category_as_main!)
  end
end
