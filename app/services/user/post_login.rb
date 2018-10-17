# frozen_string_literal: true

class User::PostLogin
  def initialize(user)
    @user = user
  end

  # This service will be invoked everytime user log in. Here we can
  # definie any initialization required for new or existing user account.
  def call
    @user.projects.find_or_create_by(name: "Services")
  end
end
