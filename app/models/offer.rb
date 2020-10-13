# frozen_string_literal: true

class Offer < ApplicationRecord
  include Offerable
  include Offer::Parameters

  searchkick word_middle: [:offer_name, :description],
            highlight: [:offer_name, :description]

  STATUSES = {
    published: "published",
    draft: "draft"
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

  enum status: STATUSES

  belongs_to :service

  counter_culture :service, column_name: proc { |model| model.published? ? "offers_count" : nil },
                  column_names: {
                      ["offers.status = ?", "published"] => "offers_count"
                  }

  has_many :project_items,
           dependent: :restrict_with_error

  validate :set_iid, on: :create
  validates :service, presence: true
  validates :iid, presence: true, numericality: true
  validates :status, presence: true

  def to_param
    iid.to_s
  end

  def open_access?
    order_type == "open_access" || order_type == "fully_open_access"
  end

  def order_required?
    order_type == "order_required"
  end

  def orderable?
    order_required? && !external?
  end

  private
    def set_iid
      self.iid = offers_count + 1 if iid.blank?
    end

    def offers_count
      service && service.offers.maximum(:iid).to_i || 0
    end
end
