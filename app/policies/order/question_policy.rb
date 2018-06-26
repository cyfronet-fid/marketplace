# frozen_string_literal: true

class Order::QuestionPolicy < ApplicationPolicy
  def create?
    record.order.active? && record.order.user == user
  end

  def permitted_attributes
    [:text]
  end
end
