# frozen_string_literal: true

class ServiceOpinion::UpdateService
  def initialize(order)
    @order = order
  end

  def call
    sum_rating = ServiceOpinion.joins(:order).where("orders.service_id = ?", @order.service_id).sum(:rating)
    service_opinion_count = @order.service.service_opinion_count += 1

    @order.service.update(rating:  sum_rating.fdiv(service_opinion_count), service_opinion_count: service_opinion_count)
  end
end
