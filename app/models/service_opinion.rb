# frozen_string_literal: true

class ServiceOpinion < ApplicationRecord
  belongs_to :order

  validates :rating, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 5 }
  after_save :update_service_rating
  private

    def update_service_rating
      @orders = Order.where(service: order.service_id)

      @service_opinions = ServiceOpinion.joins(:order).where(orders: { id: @orders })
      @rating = 0
      @service_opinions.each do |opinion|
        @rating += opinion.rating
      end

      order.service.update_attribute(:rating, @rating.fdiv(@service_opinions.size))
    end
end
