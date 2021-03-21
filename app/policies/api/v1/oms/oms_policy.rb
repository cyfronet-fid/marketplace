# frozen_string_literal: true

class Api::V1::Oms::OmsPolicy < Struct.new(:user, :oms)
  def show?
    true
    # TODO: Implement this in authorization task
  end
end
