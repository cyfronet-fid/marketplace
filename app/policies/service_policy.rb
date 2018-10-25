# frozen_string_literal: true

class ServicePolicy < ApplicationPolicy
  def show?
    true
  end

  def order?
    record.offers_count.positive?
  end
end
