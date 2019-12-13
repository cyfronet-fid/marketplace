# frozen_string_literal: true

class Executive::ExecutivePolicy < Struct.new(:user, :executive)
  def show?
    user&.executive?
  end
end
