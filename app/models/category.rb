# frozen_string_literal: true

class Category < ApplicationRecord
  extend FriendlyId
  friendly_id :name, use: :slugged

  include Parentable

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

  after_destroy :update_main_categories!

  def to_s
    self.name
  end

  private
    def store_affected_services
      # neet do store results in array since relation is lazy evaluated
      @main_services = Service.joins(:categorizations).
        where(categorizations: { category: self, main: true }).to_a
    end

    def update_main_categories!
      @main_services.each { |s| s.set_first_category_as_main! }
    end
end
