# frozen_string_literal: true

class OrderingConfiguration::ServiceContextPolicy < ServiceContextPolicy
  def show?
    super && record.service.administered_by?(user)
  end
end
