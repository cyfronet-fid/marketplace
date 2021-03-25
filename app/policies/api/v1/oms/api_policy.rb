# frozen_string_literal: true

class Api::V1::Oms::ApiPolicy < Struct.new(:user, :api)
  def show?
    # user.administrated_oms.present? TODO: implement - in authorization task #1883
    # TODO: or it may not be necessary, then we can delete this class
    true
  end
end
