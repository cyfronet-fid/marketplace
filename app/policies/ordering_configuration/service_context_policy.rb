# frozen_string_literal: true

class OrderingConfiguration::ServiceContextPolicy < ServiceContextPolicy
  def show?
    service = record.service
    super && !service.status.in?(Statusable::HIDEABLE_STATUSES) && service.owned_by?(user)
  end
end
