# frozen_string_literal: true

class OrderingConfigurationPolicy < ApplicationPolicy
  def show?
    record.administered_by?(user)
  end
end
