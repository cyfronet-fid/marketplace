# frozen_string_literal: true

class Service::Mailer::SendToSubscribers
  def initialize(service)
    @service = service
  end

  def call
    subscribers = User.where(categories_updates: true).or(User.where(research_areas_updates: true))
    subscribers.each do |subscriber|
      @common_categories = @service.categories & subscriber.categories if subscriber.categories_updates
      @common_research_areas = @service.research_areas & subscriber.research_areas if subscriber.research_areas_updates
      if @common_categories.present? || @common_research_areas.present?
        ServiceMailer.new_service(@service, @common_categories, @common_research_areas, subscriber.email).deliver_later
      end
    end
  end
end
