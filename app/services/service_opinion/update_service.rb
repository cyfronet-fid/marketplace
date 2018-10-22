# frozen_string_literal: true

class ServiceOpinion::UpdateService
  def initialize(project_item)
    @project_item = project_item
  end

  def call
    sum_rating = ServiceOpinion.joins(:project_item).where("project_items.service_id = ?", @project_item.service_id).sum(:rating)
    service_opinion_count = @project_item.service.service_opinion_count += 1

    @project_item.service.update(rating:  sum_rating.fdiv(service_opinion_count), service_opinion_count: service_opinion_count)
  end
end
