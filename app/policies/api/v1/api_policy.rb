
# frozen_string_literal: true

class Api::V1::ApiPolicy < Struct.new(:user, :token)
  def show?
    user.data_administrator?
  end
end
