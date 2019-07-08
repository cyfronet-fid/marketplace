# frozen_string_literal: true

class MessagePolicy < ApplicationPolicy
  def permitted_attributes
    [:message]
  end
end
