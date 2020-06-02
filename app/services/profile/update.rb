# frozen_string_literal: true

class Profile::Update
  def initialize(profile, params)
    @profile = profile
    @params = params
  end

  def call
    @profile.update(@params)
  end
end
