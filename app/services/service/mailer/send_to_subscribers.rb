# frozen_string_literal: true

class Service::Mailer::SendToSubscribers
  def initialize(service)
    @service = service
  end

  def call
    subscribers = User.where(categories_updates: true).or(User.where(scientific_domains_updates: true))
    subscribers.each do |subscriber|
      @common_categories = @service.categories & subscriber.categories if subscriber.categories_updates
      @common_scientific_domains =
        @service.scientific_domains & subscriber.scientific_domains if subscriber.scientific_domains_updates
      next if @common_categories.blank? && @common_scientific_domains.blank?
      ServiceMailer.new_service(
        @service,
        @common_categories,
        @common_scientific_domains,
        subscriber.email
      ).deliver_later
    end
  end
end
