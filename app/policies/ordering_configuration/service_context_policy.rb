# frozen_string_literal: true

class OrderingConfiguration::ServiceContextPolicy < ServiceContextPolicy
  def show?
    service = record.service
    super && !service.status.in?(Statusable::HIDEABLE_STATUSES) && service.administered_by?(user) &&
      service.upstream&.eosc_registry?
  end
end
