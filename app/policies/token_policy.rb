# frozen_string_literal: true

class TokenPolicy < Struct.new(:user, :token)
  def show?
    user.data_administrator?
  end
end
