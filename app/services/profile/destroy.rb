# frozen_string_literal: true

class Profile::Destroy
  def initialize(profile)
    @profile = profile
  end

  def call
    @profile.update(
      categories: [],
      scientific_domains: [],
      categories_updates: false,
      scientific_domains_updates: false
    )
  end
end
