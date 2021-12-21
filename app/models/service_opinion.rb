# frozen_string_literal: true

class ServiceOpinion < ApplicationRecord
  belongs_to :project_item

  validates :service_rating,
            :order_rating,
            presence: true,
            numericality: {
              only_integer: true,
              greater_than_or_equal_to: 1,
              less_than_or_equal_to: 5,
              message: "Please rate this question to help other users"
            }

  validates :project_item, uniqueness: true

  after_save :update_service_rating

  private

  def update_service_rating
    ServiceOpinion::UpdateService.new(project_item).call
  end
end
