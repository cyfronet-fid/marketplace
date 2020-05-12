# frozen_string_literal: true

class Profile::Destroy
  def initialize(profile)
    @profile = profile
  end

  def call
    @profile.destroy
  end
end
