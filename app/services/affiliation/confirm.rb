# frozen_string_literal: true

class Affiliation::Confirm
  def initialize(user, affiliation)
    @user = user
    @affiliation = affiliation
  end

  def call
    if !@affiliation
      @error = "Affiliation cannot be found"
      :not_found
    elsif @affiliation.user != @user
      @error = "Affiliation does not belong to you"
      :not_owned
    else
      @affiliation.update_attributes(status: :active, token: nil)
      :ok
    end
  end
end
